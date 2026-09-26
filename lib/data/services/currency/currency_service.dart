import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/services/currency/currency.dart';

/// Indonesian retail gold price per gram (Antam, via Galeri24/Pegadaian).
class GoldPrice {
  const GoldPrice({required this.sell, required this.buyback, required this.source, this.date});

  /// What a buyer pays per gram.
  final int sell;

  /// What a seller gets back per gram — the honest value of gold held.
  final int buyback;
  final String source;
  final String? date;

  Map<String, dynamic> toJson() => {'sell': sell, 'buyback': buyback, 'source': source, 'date': date};

  factory GoldPrice.fromJson(Map<String, dynamic> j) => GoldPrice(
        sell: (j['sell'] as num).round(),
        buyback: (j['buyback'] as num).round(),
        source: j['source']?.toString() ?? '',
        date: j['date']?.toString(),
      );
}

/// Live exchange rates and gold price, so accounts held in dollars, ringgit
/// or grams of gold count toward the rupiah total at today's value.
///
/// - Currencies: fawazahmed0/exchange-api on jsDelivr (free, no key, CORS,
///   ~150 currencies, updated daily), with its Cloudflare mirror as backup.
/// - Gold: Antam per-gram prices from Galeri24 (Pegadaian), fetched through
///   the Wallet worker (`/api/emas`) because Galeri24 doesn't allow
///   browsers to call it directly. When that fails, world spot gold from
///   the currency feed is used and labelled as such.
///
/// Everything is cached on the device; offline the last known values are
/// used. Rupiah-only ledgers never touch the network here.
class CurrencyService {
  CurrencyService._();
  static final instance = CurrencyService._();

  static const _fxUrls = [
    'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/idr.min.json',
    'https://latest.currency-api.pages.dev/v1/currencies/idr.min.json',
  ];
  static const _goldUrl = 'https://wallet.irsyads.com/api/emas';
  static const _troyOunceGrams = 31.1034768;
  static const _cacheKey = 'rates';

  http.Client client = http.Client();

  /// Rupiah per one whole unit of each currency (per gram for gold).
  final Map<String, double> _rates = {Currency.idr: 1};
  GoldPrice? _gold;
  DateTime? _updatedAt;
  String? _ratesDate;

  /// Bumped after every successful refresh so views can rebuild.
  final ValueNotifier<int> version = ValueNotifier(0);

  GoldPrice? get gold => _gold;
  DateTime? get updatedAt => _updatedAt;

  /// Date the currency feed was published (yyyy-mm-dd).
  String? get ratesDate => _ratesDate;

  Box<String>? get _box => Hive.isBoxOpen(AppBoxes.fxRates) ? Hive.box<String>(AppBoxes.fxRates) : null;

  static Future<void> ensureOpen() async {
    if (!Hive.isBoxOpen(AppBoxes.fxRates)) await Hive.openBox<String>(AppBoxes.fxRates);
    instance._loadCache();
  }

  void _loadCache() {
    final raw = _box?.get(_cacheKey);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      (j['rates'] as Map).forEach((k, v) => _rates[k as String] = (v as num).toDouble());
      _gold = j['gold'] == null ? null : GoldPrice.fromJson(Map<String, dynamic>.from(j['gold'] as Map));
      _updatedAt = DateTime.tryParse(j['at']?.toString() ?? '');
      _ratesDate = j['date']?.toString();
    } catch (_) {
      // A corrupt cache is just a cold start.
    }
  }

  Future<void> _saveCache() async {
    await _box?.put(
      _cacheKey,
      jsonEncode({'rates': _rates, 'gold': _gold?.toJson(), 'at': _updatedAt?.toIso8601String(), 'date': _ratesDate}),
    );
  }

  /// Rupiah per whole unit of [code]; null until a rate has been fetched.
  double? rate(String code) => _rates[code];

  bool hasRate(String code) => _rates.containsKey(code);

  /// Converts a stored amount (smallest units of [code]) to rupiah.
  /// Without a known rate the amount can't be valued and counts as 0.
  int toIdr(int minor, String? code) {
    if (code == null || code == Currency.idr) return minor;
    final r = _rates[code];
    if (r == null) return 0;
    return (minor / Currency.of(code).unit * r).round();
  }

  /// Converts rupiah to the smallest units of [code] (for prefilling the
  /// received amount of a cross-currency transfer).
  int fromIdr(int idr, String code) {
    if (code == Currency.idr) return idr;
    final r = _rates[code];
    if (r == null || r == 0) return 0;
    return (idr / r * Currency.of(code).unit).round();
  }

  /// Converts between two currencies through rupiah.
  int convert(int minor, String from, String to) => from == to ? minor : fromIdr(toIdr(minor, from), to);

  final _accounts = AccountRepository();

  /// Currency of an account (rupiah when unknown).
  String currencyOf(String accountId) {
    if (!Hive.isBoxOpen(AppBoxes.accounts)) return Currency.idr;
    return _accounts.byId(accountId)?.currencyCode ?? Currency.idr;
  }

  /// A transaction's amount in rupiah, valued at today's rate.
  int txToIdr(TxModel t) => toIdr(t.amount, currencyOf(t.accountId));

  /// True when any account is held in something other than rupiah.
  bool get hasForeignAccounts =>
      Hive.isBoxOpen(AppBoxes.accounts) && _accounts.all(includeArchived: true).any((a) => a.currencyCode != Currency.idr);

  /// Currencies the user actually holds (never rupiah).
  Set<String> heldCurrencies() => Hive.isBoxOpen(AppBoxes.accounts)
      ? {for (final a in _accounts.all(includeArchived: true)) if (a.currencyCode != Currency.idr) a.currencyCode}
      : {};

  bool _busy = false;

  /// Fetches fresh rates (and the gold price). Skipped when the last
  /// refresh is under an hour old unless [force]. Returns false when
  /// nothing could be fetched.
  Future<bool> refresh({bool force = false}) async {
    if (_busy) return false;
    if (!force && _updatedAt != null && DateTime.now().difference(_updatedAt!) < const Duration(hours: 1)) return true;
    _busy = true;
    try {
      var ok = false;
      double? spotGoldPerGram;
      for (final url in _fxUrls) {
        try {
          final res = await client.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
          if (res.statusCode != 200) continue;
          final parsed = parseFxFeed(jsonDecode(res.body) as Map<String, dynamic>);
          _rates
            ..addAll(parsed.rates)
            ..[Currency.idr] = 1;
          _ratesDate = parsed.date;
          spotGoldPerGram = parsed.spotGoldPerGram;
          ok = true;
          break;
        } catch (_) {
          continue;
        }
      }

      GoldPrice? antam;
      try {
        final res = await client.get(Uri.parse(_goldUrl)).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) antam = GoldPrice.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      } catch (_) {
        // Falls back to spot below.
      }
      if (antam != null && antam.buyback > 0) {
        _gold = antam;
        ok = true;
      } else if (spotGoldPerGram != null) {
        final spot = spotGoldPerGram.round();
        _gold = GoldPrice(sell: spot, buyback: spot, source: 'Harga emas dunia (spot)', date: _ratesDate);
      }
      if (_gold != null) _rates[Currency.gold] = _gold!.buyback.toDouble();

      if (ok) {
        _updatedAt = DateTime.now();
        await _saveCache();
        version.value++;
      }
      return ok;
    } finally {
      _busy = false;
    }
  }

  /// Parses the fawazahmed0 feed (`{"date": ..., "idr": {"usd": 0.0000558, ...}}`,
  /// units of each currency per 1 rupiah) into rupiah per unit.
  static ({Map<String, double> rates, String? date, double? spotGoldPerGram}) parseFxFeed(Map<String, dynamic> body) {
    final raw = body['idr'];
    final rates = <String, double>{};
    double? gold;
    if (raw is Map) {
      for (final c in Currency.all) {
        if (c.isRupiah || c.isGold) continue;
        final v = raw[c.code.toLowerCase()];
        if (v is num && v > 0) rates[c.code] = 1 / v;
      }
      final xau = raw['xau'];
      if (xau is num && xau > 0) gold = 1 / xau / _troyOunceGrams;
    }
    return (rates: rates, date: body['date']?.toString(), spotGoldPerGram: gold);
  }

  /// For tests: set rates without the network.
  @visibleForTesting
  void debugSetRates(Map<String, double> rates, {GoldPrice? gold}) {
    _rates
      ..clear()
      ..[Currency.idr] = 1
      ..addAll(rates);
    _gold = gold;
    if (gold != null) _rates[Currency.gold] = gold.buyback.toDouble();
  }
}

extension TxRupiah on TxModel {
  /// [amount] in rupiah at today's rate (same as [amount] for rupiah accounts).
  int get idr => CurrencyService.instance.txToIdr(this);
}

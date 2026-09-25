import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:financial_recording/config/app_config_v2.dart';

/// Latest rupiah price of one coin.
class CoinPrice {
  const CoinPrice({required this.idr, this.change24h, this.at});

  final double idr;

  /// Percent change over the last 24 hours, e.g. -2.5.
  final double? change24h;

  /// When this price was fetched.
  final DateTime? at;

  Map<String, dynamic> toJson() => {'idr': idr, 'chg': change24h, 'at': at?.toIso8601String()};

  factory CoinPrice.fromJson(Map<String, dynamic> j) => CoinPrice(
        idr: (j['idr'] as num).toDouble(),
        change24h: (j['chg'] as num?)?.toDouble(),
        at: DateTime.tryParse(j['at']?.toString() ?? ''),
      );
}

/// A coin found by [CryptoPriceService.search].
class CoinSearchResult {
  const CoinSearchResult({required this.id, required this.symbol, required this.name, this.thumb, this.rank});

  final String id;
  final String symbol;
  final String name;
  final String? thumb;
  final int? rank;
}

class CryptoPriceException implements Exception {
  const CryptoPriceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Live coin prices and coin search from CoinGecko's free public API (no
/// key; CORS-enabled, so it works on the web build too). Prices are cached
/// on the device so the portfolio still shows the last known value offline.
class CryptoPriceService {
  CryptoPriceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://api.coingecko.com/api/v3';

  Box<String> get _cache => Hive.box<String>(AppBoxes.cryptoPrices);

  /// Last known prices for [coinIds], from the device cache.
  Map<String, CoinPrice> cached(Iterable<String> coinIds) {
    final result = <String, CoinPrice>{};
    for (final id in coinIds) {
      final raw = _cache.get(id);
      if (raw == null) continue;
      try {
        result[id] = CoinPrice.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // A corrupt entry is just a cache miss.
      }
    }
    return result;
  }

  /// Fetches current rupiah prices for [coinIds] and caches them.
  Future<Map<String, CoinPrice>> fetch(Iterable<String> coinIds) async {
    final ids = coinIds.toSet().where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return {};
    final uri = Uri.parse('$_base/simple/price').replace(queryParameters: {
      'ids': ids.join(','),
      'vs_currencies': 'idr',
      'include_24hr_change': 'true',
    });
    final body = await _get(uri);
    final prices = parsePrices(body, DateTime.now());
    await _cache.putAll({for (final e in prices.entries) e.key: jsonEncode(e.value.toJson())});
    return prices;
  }

  /// Coins matching [query] by name or ticker, best-known first.
  Future<List<CoinSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final body = await _get(Uri.parse('$_base/search').replace(queryParameters: {'query': q}));
    return parseSearch(body);
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final http.Response res;
    try {
      res = await _client.get(uri, headers: {'accept': 'application/json'}).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const CryptoPriceException('Tidak bisa mengambil harga. Periksa koneksi internet.');
    }
    if (res.statusCode == 429) {
      throw const CryptoPriceException('Terlalu sering memperbarui harga. Coba lagi sebentar lagi.');
    }
    if (res.statusCode != 200) {
      throw CryptoPriceException('Layanan harga sedang bermasalah (HTTP ${res.statusCode}).');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Parses a `/simple/price` response. Coins without a rupiah price are
  /// left out.
  static Map<String, CoinPrice> parsePrices(Map<String, dynamic> body, DateTime at) {
    final result = <String, CoinPrice>{};
    for (final e in body.entries) {
      final v = e.value;
      if (v is! Map) continue;
      final idr = v['idr'];
      if (idr is! num) continue;
      result[e.key] = CoinPrice(idr: idr.toDouble(), change24h: (v['idr_24h_change'] as num?)?.toDouble(), at: at);
    }
    return result;
  }

  /// Parses a `/search` response's coins.
  static List<CoinSearchResult> parseSearch(Map<String, dynamic> body) {
    final coins = body['coins'];
    if (coins is! List) return [];
    return [
      for (final c in coins.take(25))
        if (c is Map && c['id'] is String)
          CoinSearchResult(
            id: c['id'] as String,
            symbol: (c['symbol']?.toString() ?? '').toUpperCase(),
            name: c['name']?.toString() ?? '',
            thumb: c['thumb'] as String?,
            rank: (c['market_cap_rank'] as num?)?.toInt(),
          ),
    ];
  }
}

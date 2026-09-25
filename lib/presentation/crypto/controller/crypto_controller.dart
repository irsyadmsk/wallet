import 'package:get/get.dart';
import 'package:financial_recording/data/models/crypto_model/crypto_holding_model.dart';
import 'package:financial_recording/data/repositories/crypto_repository.dart';
import 'package:financial_recording/data/services/crypto_portfolio.dart';
import 'package:financial_recording/data/services/crypto_price_service.dart';

class CryptoController extends GetxController {
  CryptoController({CryptoRepository? repository, CryptoPriceService? prices})
      : _repo = repository ?? CryptoRepository(),
        _prices = prices ?? CryptoPriceService();

  final CryptoRepository _repo;
  final CryptoPriceService _prices;

  final Rx<PortfolioSummary> summary = PortfolioSummary.of(const [], const {}).obs;
  final RxBool loadingPrices = false.obs;
  final RxnString priceError = RxnString();
  final Rxn<DateTime> pricesAt = Rxn<DateTime>();

  Map<String, CoinPrice> _latest = {};
  DateTime? _lastFetch;

  CryptoPriceService get priceService => _prices;

  @override
  void onInit() {
    super.onInit();
    refresh();
    refreshPrices();
  }

  /// Re-reads holdings and values them at the latest known prices.
  @override
  void refresh() {
    final holdings = _repo.all();
    final missing = holdings.map((h) => h.coinId).where((id) => !_latest.containsKey(id));
    _latest = {..._prices.cached(missing), ..._latest};
    summary.value = PortfolioSummary.of(holdings, _latest);
    pricesAt.value ??= _oldestPriceTime();
  }

  /// Fetches live prices. Skipped when fetched under a minute ago unless
  /// [force], since the free API is rate-limited.
  Future<void> refreshPrices({bool force = false}) async {
    if (loadingPrices.value) return;
    if (!force && _lastFetch != null && DateTime.now().difference(_lastFetch!) < const Duration(minutes: 1)) return;
    final ids = _repo.all().map((h) => h.coinId).toSet();
    if (ids.isEmpty) return;
    loadingPrices.value = true;
    try {
      final fresh = await _prices.fetch(ids);
      _latest = {..._latest, ...fresh};
      _lastFetch = DateTime.now();
      pricesAt.value = _lastFetch;
      priceError.value = null;
    } on CryptoPriceException catch (e) {
      priceError.value = e.message;
    } finally {
      loadingPrices.value = false;
      refresh();
    }
  }

  Future<void> save(CryptoHoldingModel holding) async {
    await _repo.upsert(holding);
    refresh();
    if (!_latest.containsKey(holding.coinId)) await refreshPrices(force: true);
  }

  Future<void> delete(String id) async {
    await _repo.remove(id);
    refresh();
  }

  CryptoHoldingModel? existingFor(String coinId) => _repo.byCoin(coinId);

  DateTime? _oldestPriceTime() {
    DateTime? oldest;
    for (final p in _latest.values) {
      if (p.at != null && (oldest == null || p.at!.isBefore(oldest))) oldest = p.at;
    }
    return oldest;
  }
}

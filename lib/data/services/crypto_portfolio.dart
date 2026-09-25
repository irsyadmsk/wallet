import 'package:financial_recording/data/models/crypto_model/crypto_holding_model.dart';
import 'package:financial_recording/data/services/crypto_price_service.dart';

/// One holding valued at its current price.
class HoldingValue {
  const HoldingValue({required this.holding, this.price});

  final CryptoHoldingModel holding;
  final CoinPrice? price;

  /// Current rupiah value, or null while the price is unknown.
  int? get value => price == null ? null : (holding.amount * price!.idr).round();

  /// Unrealized gain/loss, when both price and cost are known.
  int? get gain => value == null || holding.costBasis <= 0 ? null : value! - holding.costBasis;

  double? get gainPercent => gain == null ? null : gain! / holding.costBasis * 100;

  /// Rupiah moved over the last 24h, derived from the percent change.
  int? get change24hValue {
    final v = value;
    final pct = price?.change24h;
    if (v == null || pct == null) return null;
    // value = before * (1 + pct/100)  →  change = value - before
    return (v - v / (1 + pct / 100)).round();
  }
}

/// Totals over a whole portfolio.
class PortfolioSummary {
  const PortfolioSummary({
    required this.holdings,
    required this.totalValue,
    required this.costOfPriced,
    required this.change24hValue,
    required this.unpriced,
  });

  final List<HoldingValue> holdings;

  /// Sum of every holding with a known price.
  final int totalValue;

  /// Cost of the holdings that have both a price and a known cost — the
  /// base that total gain is measured against.
  final int costOfPriced;
  final int change24hValue;

  /// Holdings with no price yet (offline on first open, unknown coin).
  final int unpriced;

  int get totalGain => holdings.fold(0, (s, h) => s + (h.gain ?? 0));
  double? get totalGainPercent => costOfPriced > 0 ? totalGain / costOfPriced * 100 : null;

  double? get change24hPercent {
    final before = totalValue - change24hValue;
    return before > 0 ? change24hValue / before * 100 : null;
  }

  static PortfolioSummary of(List<CryptoHoldingModel> holdings, Map<String, CoinPrice> prices) {
    final values = [for (final h in holdings) HoldingValue(holding: h, price: prices[h.coinId])];
    var total = 0, cost = 0, change = 0, unpriced = 0;
    for (final v in values) {
      final value = v.value;
      if (value == null) {
        unpriced++;
        continue;
      }
      total += value;
      if (v.gain != null) cost += v.holding.costBasis;
      change += v.change24hValue ?? 0;
    }
    return PortfolioSummary(holdings: values, totalValue: total, costOfPriced: cost, change24hValue: change, unpriced: unpriced);
  }
}

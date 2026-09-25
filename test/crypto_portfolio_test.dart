import 'package:flutter_test/flutter_test.dart';

import 'package:financial_recording/data/models/crypto_model/crypto_holding_model.dart';
import 'package:financial_recording/data/services/crypto_portfolio.dart';
import 'package:financial_recording/data/services/crypto_price_service.dart';

CryptoHoldingModel holding(String coin, double amount, {int cost = 0}) =>
    CryptoHoldingModel(id: 'h-$coin', coinId: coin, symbol: coin.toUpperCase(), name: coin, amount: amount, costBasis: cost);

void main() {
  test('harga CoinGecko diurai, koin tanpa harga rupiah dilewati', () {
    final at = DateTime(2026, 9, 25);
    final prices = CryptoPriceService.parsePrices({
      'bitcoin': {'idr': 1500000000, 'idr_24h_change': -2.5},
      'ethereum': {'idr': 48000000.5},
      'aneh': {'usd': 1},
    }, at);
    expect(prices.keys, unorderedEquals(['bitcoin', 'ethereum']));
    expect(prices['bitcoin']!.idr, 1500000000);
    expect(prices['bitcoin']!.change24h, -2.5);
    expect(prices['ethereum']!.change24h, isNull);
  });

  test('hasil pencarian koin diurai', () {
    final r = CryptoPriceService.parseSearch({
      'coins': [
        {'id': 'solana', 'symbol': 'sol', 'name': 'Solana', 'thumb': 'https://x/sol.png', 'market_cap_rank': 7},
        {'symbol': 'tanpa-id'},
      ],
    });
    expect(r, hasLength(1));
    expect(r.single.symbol, 'SOL');
    expect(r.single.rank, 7);
  });

  test('nilai, untung/rugi, dan perubahan 24 jam portofolio', () {
    final prices = {
      'bitcoin': const CoinPrice(idr: 1000000000, change24h: 25), // naik 25%
      'ethereum': const CoinPrice(idr: 50000000),
    };
    final s = PortfolioSummary.of([
      holding('bitcoin', 0.01, cost: 8000000), // nilai 10 jt, untung 2 jt
      holding('ethereum', 1), // nilai 50 jt, modal tak diketahui
      holding('dogecoin', 100), // belum ada harga
    ], prices);

    expect(s.totalValue, 60000000);
    expect(s.unpriced, 1);
    expect(s.totalGain, 2000000);
    expect(s.totalGainPercent, closeTo(25, 1e-9)); // hanya atas modal yang diketahui
    // BTC: 10 jt sekarang, 8 jt kemarin → +2 jt; ETH tanpa data 24 jam.
    expect(s.change24hValue, 2000000);
    expect(s.holdings.first.holding.averagePrice, 800000000);
  });

  test('JSON sinkronisasi bolak-balik tanpa kehilangan pecahan koin', () {
    final h = holding('bitcoin', 0.00012345, cost: 250000)..note = 'di Indodax';
    final back = CryptoHoldingModel.fromJson(h.toJson());
    expect(back.amount, 0.00012345);
    expect(back.costBasis, 250000);
    expect(back.note, 'di Indodax');
    // Nilai dari Postgres jsonb bisa kembali sebagai int.
    expect(CryptoHoldingModel.fromJson({...h.toJson(), 'amount': 2}).amount, 2.0);
  });
}

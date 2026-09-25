import 'package:hive/hive.dart';

part 'crypto_holding_model.g.dart';

/// One coin held in the crypto portfolio: how many coins and what they cost
/// in total. The value is never stored — it comes from a live price (see
/// `CryptoPriceService`) times [amount]. Record-keeping only; the app never
/// trades or advises.
@HiveType(typeId: 19)
class CryptoHoldingModel extends HiveObject {
  @HiveField(0)
  String id;

  /// CoinGecko coin id, e.g. `bitcoin`, used to look up the live price.
  @HiveField(1)
  String coinId;

  /// Ticker shown to the user, e.g. `BTC`.
  @HiveField(2)
  String symbol;

  @HiveField(3)
  String name;

  @HiveField(4)
  String? imageUrl;

  /// Number of coins, fractional (e.g. 0.0125 BTC).
  @HiveField(5)
  double amount;

  /// Total paid for [amount], in rupiah. 0 means unknown, so no gain/loss
  /// is shown.
  @HiveField(6)
  int costBasis;

  @HiveField(7)
  String? note;

  @HiveField(8)
  int orderSeq;

  @HiveField(9)
  DateTime updatedAt;

  CryptoHoldingModel({
    required this.id,
    required this.coinId,
    required this.symbol,
    required this.name,
    this.imageUrl,
    this.amount = 0,
    this.costBasis = 0,
    this.note,
    this.orderSeq = 0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Rupiah paid per coin, or null when the cost is unknown.
  double? get averagePrice => costBasis > 0 && amount > 0 ? costBasis / amount : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'coinId': coinId,
        'symbol': symbol,
        'name': name,
        'imageUrl': imageUrl,
        'amount': amount,
        'costBasis': costBasis,
        'note': note,
        'orderSeq': orderSeq,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CryptoHoldingModel.fromJson(Map<String, dynamic> json) => CryptoHoldingModel(
        id: json['id'] as String,
        coinId: json['coinId']?.toString() ?? '',
        symbol: json['symbol']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        imageUrl: json['imageUrl'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? double.tryParse(json['amount']?.toString() ?? '') ?? 0,
        costBasis: (json['costBasis'] as num?)?.round() ?? 0,
        note: json['note'] as String?,
        orderSeq: (json['orderSeq'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

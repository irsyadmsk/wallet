import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 3)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String walletName;

  @HiveField(1)
  String categoryName;

  @HiveField(2)
  int amount;

  @HiveField(3)
  List<Map<String, dynamic>> items;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String type; // 'expense' or 'income'

  TransactionModel({
    required this.walletName,
    required this.categoryName,
    required this.amount,
    required this.items,
    required this.createdAt,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'walletName': walletName,
      'categoryName': categoryName,
      'amount': amount,
      'items': items,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['createdAt'] is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
    } else if (json['createdAt'] is String) {
      parsedDate = DateTime.tryParse(json['createdAt']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    List<Map<String, dynamic>> parsedItems = [];
    if (json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return TransactionModel(
      walletName: json['walletName']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      amount: int.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      items: parsedItems,
      createdAt: parsedDate,
      type: json['type']?.toString() ?? 'expense',
    );
  }
}

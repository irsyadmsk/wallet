import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 3)
class TransactionModel {
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
}

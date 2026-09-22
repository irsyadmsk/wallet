import 'package:hive/hive.dart';

part 'tx_item_model.g.dart';

@HiveType(typeId: 7)
class TxItemModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int amount;

  @HiveField(2)
  int qty;

  TxItemModel({required this.name, required this.amount, this.qty = 1});

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount, 'qty': qty};

  factory TxItemModel.fromJson(Map<String, dynamic> json) => TxItemModel(
        name: json['name']?.toString() ?? '',
        amount: int.tryParse(json['amount'].toString()) ?? 0,
        qty: int.tryParse(json['qty'].toString()) ?? 1,
      );
}

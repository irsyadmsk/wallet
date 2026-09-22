import 'package:hive/hive.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

part 'template_model.g.dart';

@HiveType(typeId: 16)
class QuickTemplateModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  TxType type;

  @HiveField(3)
  int amount;

  @HiveField(4)
  String? categoryId;

  @HiveField(5)
  String? accountId;

  @HiveField(6)
  String iconName;

  @HiveField(7)
  int colorValue;

  @HiveField(8)
  int orderSeq;

  QuickTemplateModel({
    required this.id,
    required this.name,
    this.type = TxType.expense,
    required this.amount,
    this.categoryId,
    this.accountId,
    this.iconName = 'receipt',
    this.colorValue = 0xFF0D9488,
    this.orderSeq = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'amount': amount,
        'categoryId': categoryId,
        'accountId': accountId,
        'iconName': iconName,
        'colorValue': colorValue,
        'orderSeq': orderSeq,
      };

  factory QuickTemplateModel.fromJson(Map<String, dynamic> json) => QuickTemplateModel(
        id: json['id'] as String,
        name: json['name']?.toString() ?? '',
        type: TxType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TxType.expense,
        ),
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        categoryId: json['categoryId'] as String?,
        accountId: json['accountId'] as String?,
        iconName: json['iconName']?.toString() ?? 'receipt',
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF0D9488,
        orderSeq: (json['orderSeq'] as num?)?.toInt() ?? 0,
      );
}

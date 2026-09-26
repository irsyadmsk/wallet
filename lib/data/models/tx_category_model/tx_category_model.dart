import 'package:hive/hive.dart';

part 'tx_category_model.g.dart';

@HiveType(typeId: 5)
class TxCategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? emoji;

  @HiveField(3)
  int typeCode; // 0 = income, 1 = expense, 2 = account group (see AccountGroupRepository)

  static const accountGroupType = 2;

  @HiveField(4)
  String? parentId;

  @HiveField(5)
  String? iconPath;

  @HiveField(6)
  int colorValue;

  @HiveField(7)
  int orderSeq;

  @HiveField(8)
  bool isArchived;

  @HiveField(9)
  String? externalId;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  TxCategoryModel({
    required this.id,
    required this.name,
    this.emoji,
    required this.typeCode,
    this.parentId,
    this.iconPath,
    this.colorValue = 0xFF64748B,
    this.orderSeq = 0,
    this.isArchived = false,
    this.externalId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isIncome => typeCode == 0;
  bool get isSub => parentId != null && parentId!.isNotEmpty;
  String get displayName => emoji == null || emoji!.isEmpty ? name : '$emoji $name';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'typeCode': typeCode,
        'parentId': parentId,
        'iconPath': iconPath,
        'colorValue': colorValue,
        'orderSeq': orderSeq,
        'isArchived': isArchived,
        'externalId': externalId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TxCategoryModel.fromJson(Map<String, dynamic> json) => TxCategoryModel(
        id: json['id'] as String,
        name: json['name']?.toString() ?? '',
        emoji: json['emoji'] as String?,
        typeCode: int.tryParse(json['typeCode'].toString()) ?? 1,
        parentId: (json['parentId'] as String?)?.isEmpty == true ? null : json['parentId'] as String?,
        iconPath: json['iconPath'] as String?,
        colorValue: int.tryParse(json['colorValue'].toString()) ?? 0xFF64748B,
        orderSeq: int.tryParse(json['orderSeq'].toString()) ?? 0,
        isArchived: json['isArchived'] as bool? ?? false,
        externalId: json['externalId'] as String?,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

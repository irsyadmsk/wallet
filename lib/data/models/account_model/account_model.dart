import 'package:hive/hive.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';

part 'account_model.g.dart';

@HiveType(typeId: 4)
class AccountModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int groupCode;

  @HiveField(3)
  bool isLiability;

  @HiveField(4)
  String? iconPath;

  @HiveField(5)
  int colorValue;

  @HiveField(6)
  int openingBalance;

  @HiveField(7)
  String currencyCode;

  @HiveField(8)
  int orderSeq;

  @HiveField(9)
  bool isArchived;

  @HiveField(10)
  String? note;

  @HiveField(11)
  int cachedBalance;

  @HiveField(12)
  String? externalId;

  @HiveField(13)
  DateTime createdAt;

  @HiveField(14)
  DateTime updatedAt;

  /// Day of month (1-31) the card/liability statement is due, if known.
  /// Used to show a "jatuh tempo" reminder on liability accounts.
  @HiveField(15)
  int? dueDay;

  /// Soft-delete timestamp — set instead of physically removing the row, so
  /// an accidental delete can be undone from Settings > Akun Terhapus.
  @HiveField(16)
  DateTime? deletedAt;

  /// False keeps the account out of "Total saldo"/net worth (e.g. a
  /// savings pot the user doesn't want counted). Balance still shown.
  @HiveField(17, defaultValue: true)
  bool includeInTotal;

  AccountModel({
    required this.id,
    required this.name,
    required this.groupCode,
    bool? isLiability,
    this.iconPath,
    this.colorValue = 0xFF4F46E5,
    this.openingBalance = 0,
    this.currencyCode = 'IDR',
    this.orderSeq = 0,
    this.isArchived = false,
    this.note,
    this.cachedBalance = 0,
    this.externalId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.dueDay,
    this.deletedAt,
    this.includeInTotal = true,
  })  : isLiability = isLiability ?? AccountGroupType.fromCode(groupCode).isLiabilityDefault,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  AccountGroupType get group => AccountGroupType.fromCode(groupCode);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'groupCode': groupCode,
        'isLiability': isLiability,
        'iconPath': iconPath,
        'colorValue': colorValue,
        'openingBalance': openingBalance,
        'currencyCode': currencyCode,
        'orderSeq': orderSeq,
        'isArchived': isArchived,
        'note': note,
        'cachedBalance': cachedBalance,
        'externalId': externalId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'dueDay': dueDay,
        'deletedAt': deletedAt?.toIso8601String(),
        'includeInTotal': includeInTotal,
      };

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'] as String,
        name: json['name']?.toString() ?? '',
        groupCode: int.tryParse(json['groupCode'].toString()) ?? 7,
        isLiability: json['isLiability'] as bool?,
        iconPath: json['iconPath'] as String?,
        colorValue: int.tryParse(json['colorValue'].toString()) ?? 0xFF4F46E5,
        openingBalance: int.tryParse(json['openingBalance'].toString()) ?? 0,
        currencyCode: json['currencyCode']?.toString() ?? 'IDR',
        orderSeq: int.tryParse(json['orderSeq'].toString()) ?? 0,
        isArchived: json['isArchived'] as bool? ?? false,
        note: json['note'] as String?,
        cachedBalance: int.tryParse(json['cachedBalance'].toString()) ?? 0,
        externalId: json['externalId'] as String?,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
        dueDay: json['dueDay'] == null ? null : int.tryParse(json['dueDay'].toString()),
        deletedAt: json['deletedAt'] == null ? null : DateTime.tryParse(json['deletedAt'].toString()),
        includeInTotal: json['includeInTotal'] as bool? ?? true,
      );
}

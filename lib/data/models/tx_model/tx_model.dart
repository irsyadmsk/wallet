import 'package:hive/hive.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/data/models/tx_model/tx_item_model.dart';

part 'tx_model.g.dart';

@HiveType(typeId: 6)
class TxModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  TxType type;

  @HiveField(2)
  int amount; // always positive; sign derives from [type]

  @HiveField(3)
  String accountId;

  @HiveField(4)
  String? toAccountId; // transfer destination only

  @HiveField(5)
  String? categoryId; // null for transfer

  @HiveField(6)
  DateTime date;

  @HiveField(7)
  String? memo;

  @HiveField(8)
  List<TxItemModel> items;

  @HiveField(9)
  List<String> tagIds;

  @HiveField(10)
  String? recurringRuleId;

  @HiveField(11)
  bool isExcludedFromBudget;

  @HiveField(12)
  String? externalId;

  @HiveField(13)
  String? externalPairId;

  @HiveField(14)
  DateTime createdAt;

  @HiveField(15)
  DateTime updatedAt;

  @HiveField(16)
  String? imagePath; // Local path to attached receipt or bill photo

  /// Extra amount deducted from [accountId] on top of [amount] for a
  /// transfer — the source account loses `amount + transferFee`, but the
  /// destination still only receives `amount`. Null/zero for every other
  /// transaction type.
  @HiveField(17)
  int? transferFee;

  TxModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    required this.date,
    this.memo,
    List<TxItemModel>? items,
    List<String>? tagIds,
    this.recurringRuleId,
    this.isExcludedFromBudget = false,
    this.externalId,
    this.externalPairId,
    this.imagePath,
    this.transferFee,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : items = items ?? [],
        tagIds = tagIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isTransfer => type == TxType.transfer;
  bool get isIncome => type == TxType.income;
  bool get isExpense => type == TxType.expense;

  /// Signed effect of this transaction on [accountId]'s balance.
  int get signedAmountOnPrimaryAccount {
    switch (type) {
      case TxType.income:
        return amount;
      case TxType.expense:
        return -amount;
      case TxType.transfer:
        return -(amount + (transferFee ?? 0));
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'categoryId': categoryId,
        'date': date.toIso8601String(),
        'memo': memo,
        'items': items.map((e) => e.toJson()).toList(),
        'tagIds': tagIds,
        'recurringRuleId': recurringRuleId,
        'isExcludedFromBudget': isExcludedFromBudget,
        'externalId': externalId,
        'externalPairId': externalPairId,
        'imagePath': imagePath,
        'transferFee': transferFee,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TxModel.fromJson(Map<String, dynamic> json) => TxModel(
        id: json['id'] as String,
        type: TxType.values.firstWhere((t) => t.name == json['type'], orElse: () => TxType.expense),
        amount: int.tryParse(json['amount'].toString()) ?? 0,
        accountId: json['accountId']?.toString() ?? '',
        toAccountId: json['toAccountId'] as String?,
        categoryId: json['categoryId'] as String?,
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        memo: (json['memo'] as String?)?.isEmpty == true ? null : json['memo'] as String?,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => TxItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        tagIds: (json['tagIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        recurringRuleId: json['recurringRuleId'] as String?,
        isExcludedFromBudget: json['isExcludedFromBudget'] as bool? ?? false,
        externalId: json['externalId'] as String?,
        externalPairId: json['externalPairId'] as String?,
        imagePath: json['imagePath'] as String?,
        transferFee: json['transferFee'] == null ? null : int.tryParse(json['transferFee'].toString()),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

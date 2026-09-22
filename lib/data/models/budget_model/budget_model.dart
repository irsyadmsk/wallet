import 'package:hive/hive.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

part 'budget_model.g.dart';

/// A monthly budget "template". A changed limit is a *new* row with a later
/// [startMonth] so history stays truthful — see [BudgetModel.isActiveFor].
@HiveType(typeId: 9)
class BudgetModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? categoryId; // null + isTotal=true => overall monthly budget

  @HiveField(2)
  bool isTotal;

  @HiveField(3)
  bool includeSubcategories;

  @HiveField(4)
  int amount;

  @HiveField(5)
  BudgetPeriod period;

  @HiveField(6)
  DateTime startMonth;

  @HiveField(7)
  DateTime? endMonth;

  @HiveField(8)
  bool isArchived;

  BudgetModel({
    required this.id,
    this.categoryId,
    this.isTotal = false,
    this.includeSubcategories = true,
    required this.amount,
    this.period = BudgetPeriod.monthly,
    required this.startMonth,
    this.endMonth,
    this.isArchived = false,
  });

  bool coversMonth(DateTime month) {
    final m = DateTime(month.year, month.month);
    final s = DateTime(startMonth.year, startMonth.month);
    if (m.isBefore(s)) return false;
    if (endMonth != null) {
      final e = DateTime(endMonth!.year, endMonth!.month);
      if (m.isAfter(e)) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'isTotal': isTotal,
        'includeSubcategories': includeSubcategories,
        'amount': amount,
        'period': period.name,
        'startMonth': startMonth.toIso8601String(),
        'endMonth': endMonth?.toIso8601String(),
        'isArchived': isArchived,
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String?,
        isTotal: json['isTotal'] as bool? ?? false,
        includeSubcategories: json['includeSubcategories'] as bool? ?? true,
        amount: int.tryParse(json['amount'].toString()) ?? 0,
        period: BudgetPeriod.values.firstWhere((p) => p.name == json['period'], orElse: () => BudgetPeriod.monthly),
        startMonth: DateTime.tryParse(json['startMonth']?.toString() ?? '') ?? DateTime.now(),
        endMonth: json['endMonth'] == null ? null : DateTime.tryParse(json['endMonth'].toString()),
        isArchived: json['isArchived'] as bool? ?? false,
      );
}

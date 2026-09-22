import 'package:financial_recording/data/models/budget_model/budget_model.dart';
import 'package:financial_recording/data/repositories/budget_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/repositories/tx_query.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

class BudgetProgress {
  final BudgetModel? budget;
  final String? categoryId;
  final int limit;
  final int spent;
  final DateTime month;

  BudgetProgress({required this.budget, this.categoryId, required this.limit, required this.spent, required this.month});

  int get remaining => limit - spent;
  double get percent => limit <= 0 ? 0 : (spent / limit).clamp(0, 999) / 1;
  bool get isOver => spent > limit && limit > 0;
  bool get isNearLimit => !isOver && limit > 0 && spent / limit >= 0.8;
}

class BudgetServiceV2 {
  BudgetServiceV2({
    BudgetRepository? budgetRepository,
    TxCategoryRepository? categoryRepository,
    TxRepository? txRepository,
  })  : _budgets = budgetRepository ?? BudgetRepository(),
        _categories = categoryRepository ?? TxCategoryRepository(),
        _txs = txRepository ?? TxRepository();

  final BudgetRepository _budgets;
  final TxCategoryRepository _categories;
  final TxRepository _txs;

  int _spentForCategory(String? categoryId, DateTime from, DateTime to, {required bool includeSub}) {
    Set<String>? categoryIds;
    if (categoryId != null) {
      categoryIds = {categoryId};
      if (includeSub) {
        categoryIds.addAll(_categories.childrenOf(categoryId).map((c) => c.id));
      }
    }
    final txs = _txs.query(TxQuery(
      from: from,
      to: to,
      types: {TxType.expense},
      categoryIds: categoryIds,
    ));
    return txs.where((t) => !t.isExcludedFromBudget).fold(0, (sum, t) => sum + t.amount);
  }

  BudgetProgress overallProgress(DateTime month) {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 1).subtract(const Duration(milliseconds: 1));
    final budget = _budgets.activeFor(categoryId: null, month: month);
    final spent = _txs
        .query(TxQuery(from: from, to: to, types: {TxType.expense}))
        .where((t) => !t.isExcludedFromBudget)
        .fold(0, (sum, t) => sum + t.amount);
    return BudgetProgress(budget: budget, categoryId: null, limit: budget?.amount ?? 0, spent: spent, month: month);
  }

  List<BudgetProgress> categoryProgress(DateTime month) {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 1).subtract(const Duration(milliseconds: 1));
    final result = <BudgetProgress>[];
    for (final b in _budgets.all().where((b) => !b.isTotal && b.coversMonth(month))) {
      // only the most-recent applicable row per category
      final active = _budgets.activeFor(categoryId: b.categoryId, month: month);
      if (active?.id != b.id) continue;
      final spent = _spentForCategory(b.categoryId, from, to, includeSub: b.includeSubcategories);
      result.add(BudgetProgress(budget: b, categoryId: b.categoryId, limit: b.amount, spent: spent, month: month));
    }
    result.sort((a, b) => b.percent.compareTo(a.percent));
    return result;
  }
}

import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/goal_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_query.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/currency/currency_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

class PlanLinkOption {
  const PlanLinkOption(this.id, this.label);
  final String id, label;
}

/// What the ledger says about a linked plan item. Null fields mean "not
/// linked" or "the linked record no longer exists".
class PlanItemLinks {
  const PlanItemLinks({this.categoryLabel, this.ledgerSpent, this.accountLabel,
    this.accountBalance, this.goalLabel, this.goalCurrent, this.goalTarget});
  final String? categoryLabel, accountLabel, goalLabel;
  final int? ledgerSpent, accountBalance, goalCurrent, goalTarget;
  bool get isEmpty => categoryLabel == null && accountLabel == null && goalLabel == null;
}

/// The planner's only window onto the ledger, and it is read-only: the
/// planner never writes a transaction, balance or goal through it.
abstract class PlanLedger {
  bool get available;
  List<PlanLinkOption> categories();
  List<PlanLinkOption> accounts();
  List<PlanLinkOption> goals();

  /// [month] is null on the template and one-off tabs, where a month's
  /// spending has no meaning.
  PlanItemLinks linksFor(AllocationItem item, DateTime? month);
}

class NoPlanLedger implements PlanLedger {
  const NoPlanLedger();
  @override
  bool get available => false;
  @override
  List<PlanLinkOption> categories() => const [];
  @override
  List<PlanLinkOption> accounts() => const [];
  @override
  List<PlanLinkOption> goals() => const [];
  @override
  PlanItemLinks linksFor(AllocationItem item, DateTime? month) => const PlanItemLinks();
}

class HivePlanLedger implements PlanLedger {
  HivePlanLedger();
  final _categories = TxCategoryRepository();
  final _accounts = AccountRepository();
  final _goals = FinancialGoalRepository();
  final _txs = TxRepository();

  /// The app's own ledger when its boxes are open, otherwise nothing (widget
  /// tests, or before start-up finishes).
  static PlanLedger ifOpen() => [AppBoxes.categories, AppBoxes.accounts,
        AppBoxes.goals, AppBoxes.transactions].every(Hive.isBoxOpen)
      ? HivePlanLedger() : const NoPlanLedger();

  @override
  bool get available => true;

  @override
  List<PlanLinkOption> categories() => [
    for (final c in _categories.byType(1))
      PlanLinkOption(c.id, _categories.pathName(c.id)),
  ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

  @override
  List<PlanLinkOption> accounts() =>
      [for (final a in _accounts.all()) PlanLinkOption(a.id, a.name)];

  @override
  List<PlanLinkOption> goals() =>
      [for (final g in _goals.all()) PlanLinkOption(g.id, g.title)];

  @override
  PlanItemLinks linksFor(AllocationItem item, DateTime? month) {
    final category = item.categoryId == null ? null : _categories.byId(item.categoryId!);
    int? spent;
    if (category != null && month != null) {
      final ids = {category.id, for (final c in _categories.childrenOf(category.id)) c.id};
      spent = _txs.query(TxQuery(
        from: DateTime(month.year, month.month),
        // The query's upper bound is inclusive; stop just short of next month.
        to: DateTime(month.year, month.month + 1).subtract(const Duration(milliseconds: 1)),
        types: {TxType.expense}, categoryIds: ids,
      )).fold<int>(0, (s, t) => s + t.idr);
    }
    final account = item.accountId == null ? null
        : _accounts.all(includeArchived: true).where((a) => a.id == item.accountId).firstOrNull;
    final goal = item.goalId == null ? null : _goals.byId(item.goalId!);
    return PlanItemLinks(
      categoryLabel: category == null ? null : _categories.pathName(category.id),
      ledgerSpent: spent,
      accountLabel: account?.name, accountBalance: account?.balanceIdr,
      goalLabel: goal?.title, goalCurrent: goal?.currentAmount,
      goalTarget: goal?.targetAmount,
    );
  }
}

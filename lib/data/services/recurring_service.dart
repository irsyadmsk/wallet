import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/repositories/recurring_repository.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

/// Posts due recurring transactions on app launch/resume. There is no
/// background task runner in this local-only Flutter app (no
/// workmanager/alarm-manager — those need native config and don't exist on
/// desktop), so recurring bills/salary are posted the moment the user opens
/// the app, catching up on anything missed while it was closed.
class RecurringService {
  RecurringService({RecurringRepository? recurringRepository, LedgerService? ledgerService})
      : _recurring = recurringRepository ?? RecurringRepository(),
        _ledger = ledgerService ?? LedgerService();

  final RecurringRepository _recurring;
  final LedgerService _ledger;

  /// Returns the number of transactions auto-posted.
  Future<int> catchUp(DateTime now) async {
    var posted = 0;
    for (final rule in _recurring.all().where((r) => r.isActive && r.autoPost)) {
      var guard = 0;
      while (!rule.nextRunDate.isAfter(now) && guard < 60) {
        guard++;
        if (rule.endDate != null && rule.nextRunDate.isAfter(rule.endDate!)) break;
        if (rule.type == TxType.transfer && rule.toAccountId != null) {
          await _ledger.addTransfer(
            fromAccountId: rule.accountId,
            toAccountId: rule.toAccountId!,
            amount: rule.amount,
            date: rule.nextRunDate,
            memo: rule.memo,
          );
        } else if (rule.type == TxType.income) {
          await _ledger.addIncome(
            accountId: rule.accountId,
            categoryId: rule.categoryId ?? '',
            amount: rule.amount,
            date: rule.nextRunDate,
            memo: rule.memo,
          );
        } else {
          await _ledger.addExpense(
            accountId: rule.accountId,
            categoryId: rule.categoryId ?? '',
            amount: rule.amount,
            date: rule.nextRunDate,
            memo: rule.memo,
          );
        }
        posted++;
        rule.lastPostedDate = rule.nextRunDate;
        rule.nextRunDate = rule.computeNextRun(rule.nextRunDate);
      }
      await _recurring.upsert(rule);
    }
    return posted;
  }

  /// Rules due within [horizonDays] that require manual confirmation
  /// (`autoPost == false`) — surfaced as a "Jatuh tempo" list.
  List<RecurringRuleModel> dueForConfirmation(DateTime now, {int horizonDays = 3}) {
    final horizon = now.add(Duration(days: horizonDays));
    return _recurring
        .all()
        .where((r) => r.isActive && !r.autoPost && !r.nextRunDate.isAfter(horizon))
        .toList();
  }

  Future<void> confirmPost(String ruleId, {DateTime? on}) async {
    final rule = _recurring.byId(ruleId);
    if (rule == null) return;
    final date = on ?? rule.nextRunDate;
    if (rule.type == TxType.transfer && rule.toAccountId != null) {
      await _ledger.addTransfer(
        fromAccountId: rule.accountId,
        toAccountId: rule.toAccountId!,
        amount: rule.amount,
        date: date,
        memo: rule.memo,
      );
    } else if (rule.type == TxType.income) {
      await _ledger.addIncome(
        accountId: rule.accountId,
        categoryId: rule.categoryId ?? '',
        amount: rule.amount,
        date: date,
        memo: rule.memo,
      );
    } else {
      await _ledger.addExpense(
        accountId: rule.accountId,
        categoryId: rule.categoryId ?? '',
        amount: rule.amount,
        date: date,
        memo: rule.memo,
      );
    }
    rule.lastPostedDate = date;
    rule.nextRunDate = rule.computeNextRun(rule.nextRunDate);
    await _recurring.upsert(rule);
  }
}

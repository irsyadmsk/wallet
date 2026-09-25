import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/repositories/recurring_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

/// Posts due recurring transactions on app launch/resume. There is no
/// background task runner in this local-only Flutter app (no
/// workmanager/alarm-manager — those need native config and don't exist on
/// desktop), so recurring bills/salary are posted the moment the user opens
/// the app, catching up on anything missed while it was closed.
class RecurringService {
  RecurringService({RecurringRepository? recurringRepository, LedgerService? ledgerService, TxRepository? txRepository})
      : _recurring = recurringRepository ?? RecurringRepository(),
        _ledger = ledgerService ?? LedgerService(),
        _txs = txRepository ?? TxRepository();

  final RecurringRepository _recurring;
  final LedgerService _ledger;
  final TxRepository _txs;

  /// Returns the number of transactions auto-posted.
  Future<int> catchUp(DateTime now) async {
    var posted = 0;
    for (final rule in _recurring.all().where((r) => r.isActive && r.autoPost)) {
      var guard = 0;
      while (!rule.nextRunDate.isAfter(now) && guard < 60) {
        guard++;
        if (rule.endDate != null && rule.nextRunDate.isAfter(rule.endDate!)) break;
        if (await _post(rule, rule.nextRunDate)) posted++;
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
    await _post(rule, date, occurrence: rule.nextRunDate);
    rule.lastPostedDate = date;
    rule.nextRunDate = rule.computeNextRun(rule.nextRunDate);
    await _recurring.upsert(rule);
  }

  /// Id of the transaction posted for [rule]'s occurrence due on [date].
  ///
  /// Deterministic, so two devices of the same ledger (say the phone app
  /// and the web app, both opened on payday) post the *same* row instead of
  /// recording the salary or bill twice; sync then merges them into one.
  static String occurrenceId(String ruleId, DateTime date) =>
      'rec-$ruleId-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  /// Posts one occurrence, dated [date]. [occurrence] (defaults to [date])
  /// is the due date that identifies it. Returns false when that occurrence
  /// is already in the ledger, e.g. posted by another device and synced.
  Future<bool> _post(RecurringRuleModel rule, DateTime date, {DateTime? occurrence}) async {
    final id = occurrenceId(rule.id, occurrence ?? date);
    if (_txs.byId(id) != null) return false;
    if (rule.type == TxType.transfer && rule.toAccountId != null) {
      await _ledger.addTransfer(
        id: id,
        fromAccountId: rule.accountId,
        toAccountId: rule.toAccountId!,
        amount: rule.amount,
        date: date,
        memo: rule.memo,
      );
    } else if (rule.type == TxType.income) {
      await _ledger.addIncome(
        id: id,
        accountId: rule.accountId,
        categoryId: rule.categoryId ?? '',
        amount: rule.amount,
        date: date,
        memo: rule.memo,
      );
    } else {
      await _ledger.addExpense(
        id: id,
        accountId: rule.accountId,
        categoryId: rule.categoryId ?? '',
        amount: rule.amount,
        date: date,
        memo: rule.memo,
      );
    }
    return true;
  }
}

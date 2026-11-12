import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/debt_model/debt_model.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

enum BillSource { recurring, debt, account }

/// Money expected to move on a date. Read-only projection: building these
/// never posts a transaction or changes a rule.
class BillEvent {
  const BillEvent({
    required this.date,
    required this.title,
    required this.source,
    this.amount,
    this.income = false,
    this.neutral = false,
    this.automatic = false,
    this.ruleId,
  });

  /// Day only (midnight local).
  final DateTime date;
  final String title;
  final BillSource source;

  /// Rupiah, or null when the amount is unknown (a foreign-currency card).
  final int? amount;

  /// Money in rather than out.
  final bool income;

  /// A transfer between own accounts: neither in nor out.
  final bool neutral;

  /// Posted by Wallet on the day, without confirmation.
  final bool automatic;
  final String? ruleId;
}

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Events on days in `[from, to)`, soonest first.
List<BillEvent> billEvents({
  required DateTime from,
  required DateTime to,
  Iterable<RecurringRuleModel> rules = const [],
  Iterable<DebtLoanModel> debts = const [],
  Iterable<AccountModel> accounts = const [],
}) {
  final start = dayOf(from), end = dayOf(to);
  bool inside(DateTime d) => !d.isBefore(start) && d.isBefore(end);
  final out = <BillEvent>[];

  for (final r in rules.where((r) => r.isActive)) {
    var due = r.nextRunDate;
    for (var guard = 0; guard < 800 && dayOf(due).isBefore(end); guard++) {
      if (r.endDate != null && due.isAfter(r.endDate!)) break;
      if (inside(dayOf(due))) {
        out.add(BillEvent(
          date: dayOf(due),
          title: r.memo?.trim().isNotEmpty == true ? r.memo!.trim() : 'Transaksi berulang',
          source: BillSource.recurring,
          amount: r.amount,
          income: r.type == TxType.income,
          neutral: r.type == TxType.transfer,
          automatic: r.autoPost,
          ruleId: r.id,
        ));
      }
      final next = r.computeNextRun(due);
      if (!next.isAfter(due)) break;
      due = next;
    }
  }

  for (final d in debts.where((d) => !d.isSettled && d.dueDate != null)) {
    final due = dayOf(d.dueDate!);
    if (!inside(due)) continue;
    out.add(BillEvent(
      date: due,
      title: d.isLoan ? 'Piutang dari ${d.personName}' : 'Utang kepada ${d.personName}',
      source: BillSource.debt,
      amount: d.remainingAmount,
      income: d.isLoan,
    ));
  }

  for (final a in accounts.where((a) =>
      a.isLiability && a.dueDay != null && !a.isArchived && a.deletedAt == null)) {
    final owed = a.cachedBalance < 0 ? -a.cachedBalance : 0;
    if (owed == 0) continue;
    for (var m = DateTime(start.year, start.month); m.isBefore(end);
        m = DateTime(m.year, m.month + 1)) {
      final last = DateTime(m.year, m.month + 1, 0).day;
      final due = DateTime(m.year, m.month, a.dueDay! > last ? last : a.dueDay!);
      if (!inside(due)) continue;
      out.add(BillEvent(
        date: due,
        title: 'Jatuh tempo ${a.name}',
        source: BillSource.account,
        amount: a.currencyCode == 'IDR' ? owed : null,
      ));
    }
  }

  out.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : a.title.compareTo(b.title);
  });
  return out;
}

/// What the home screen should nudge about: anything due by tomorrow (H-1),
/// including what is already late. Recurring rules awaiting manual
/// confirmation are left to the existing "Jatuh tempo" card, which can post
/// them.
List<BillEvent> billReminders({
  required DateTime today,
  Iterable<RecurringRuleModel> rules = const [],
  Iterable<DebtLoanModel> debts = const [],
  Iterable<AccountModel> accounts = const [],
}) {
  final now = dayOf(today);
  return billEvents(
    from: DateTime(now.year, now.month, now.day - 60),
    to: DateTime(now.year, now.month, now.day + 2),
    rules: rules.where((r) => r.autoPost),
    debts: debts,
    accounts: accounts,
  ).where((e) {
    // A card's past due dates are not tracked as paid or unpaid; only the
    // coming one is a reminder.
    if (e.source == BillSource.account) return !e.date.isBefore(now);
    return true;
  }).toList();
}

/// "Terlambat 3 hari", "Hari ini", "Besok", "5 hari lagi".
String dueLabel(DateTime date, DateTime today) {
  // UTC dates, so a daylight-saving shift never turns one day into zero.
  final days = DateTime.utc(date.year, date.month, date.day)
      .difference(DateTime.utc(today.year, today.month, today.day))
      .inDays;
  if (days < 0) return 'Terlambat ${-days} hari';
  if (days == 0) return 'Hari ini';
  if (days == 1) return 'Besok';
  return '$days hari lagi';
}

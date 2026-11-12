import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/data/services/bill_calendar.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/util/money/money_format.dart';

/// A month of expected money movements: recurring rules, debts with a due
/// date and liability accounts with a due day. Display only.
class BillCalendar extends StatefulWidget {
  const BillCalendar({super.key, required this.load, this.today});

  /// Events on days in `[from, to)`.
  final List<BillEvent> Function(DateTime from, DateTime to) load;
  final DateTime? today;

  @override
  State<BillCalendar> createState() => _BillCalendarState();
}

class _BillCalendarState extends State<BillCalendar> {
  late final DateTime _today = dayOf(widget.today ?? DateTime.now());
  late DateTime _month = DateTime(_today.year, _today.month);
  late DateTime? _selected = _today;

  static const _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  void _shift(int by) => setState(() {
    _month = DateTime(_month.year, _month.month + by);
    _selected = _month.year == _today.year && _month.month == _today.month
        ? _today
        : null;
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final events = widget.load(_month, DateTime(_month.year, _month.month + 1));
    final byDay = <int, List<BillEvent>>{};
    for (final e in events) {
      byDay.putIfAbsent(e.date.day, () => []).add(e);
    }
    final out = events.where((e) => !e.income && !e.neutral)
        .fold(0, (s, e) => s + (e.amount ?? 0));
    final shown = _selected == null ? events : (byDay[_selected!.day] ?? const []);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = DateTime(_month.year, _month.month, 1).weekday - 1;
    final cells = lead + days;
    final rows = (cells / 7).ceil();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kalender tagihan', style: Theme.of(context).textTheme.titleMedium),
              AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.base),
                child: Text(DateFormat('MMMM yyyy', 'id_ID').format(_month),
                  key: ValueKey(_month),
                  style: TextStyle(fontSize: 13, color: c.textSecondary)),
              ),
            ])),
          IconButton(tooltip: 'Bulan sebelumnya', onPressed: () => _shift(-1),
            icon: const Icon(Icons.chevron_left)),
          IconButton(tooltip: 'Bulan berikutnya', onPressed: () => _shift(1),
            icon: const Icon(Icons.chevron_right)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          for (final w in _weekdays)
            Expanded(child: Center(child: ExcludeSemantics(child: Text(w,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: c.textSecondary))))),
        ]),
        const SizedBox(height: 4),
        for (var r = 0; r < rows; r++)
          Row(children: [
            for (var col = 0; col < 7; col++)
              Expanded(child: _cell(c, r * 7 + col - lead + 1, days, byDay)),
          ]),
        const SizedBox(height: 12),
        Divider(height: 1, color: c.border),
        const SizedBox(height: 12),
        Text(
          _selected == null
              ? '${events.length} jatuh tempo bulan ini · keluar ${out.rupiah}'
              : DateFormat('EEEE, d MMMM', 'id_ID').format(_selected!),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: c.textPrimary)),
        const SizedBox(height: 6),
        AnimatedSize(
          duration: AppMotion.of(context, AppMotion.base),
          curve: AppMotion.morph,
          alignment: Alignment.topCenter,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (shown.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(
                _selected == null ? 'Tidak ada jatuh tempo bulan ini.'
                    : 'Tidak ada jatuh tempo pada tanggal ini.',
                style: TextStyle(fontSize: 13, color: c.textSecondary))),
            for (final e in shown) BillEventRow(event: e, today: _today,
              showDate: _selected == null),
            if (_selected != null && events.isNotEmpty)
              Align(alignment: AlignmentDirectional.centerStart, child: TextButton(
                onPressed: () => setState(() => _selected = null),
                child: Text('Lihat semua ${events.length} jatuh tempo bulan ini'))),
          ]),
        ),
      ]),
    );
  }

  Widget _cell(AppColors c, int day, int days, Map<int, List<BillEvent>> byDay) {
    if (day < 1 || day > days) return const SizedBox(height: 48);
    final date = DateTime(_month.year, _month.month, day);
    final list = byDay[day] ?? const <BillEvent>[];
    final selected = _selected == date, today = date == _today;
    return Semantics(
      button: true, selected: selected,
      label: '${DateFormat('d MMMM', 'id_ID').format(date)}'
          '${today ? ', hari ini' : ''}'
          ', ${list.isEmpty ? 'tidak ada jatuh tempo' : '${list.length} jatuh tempo'}',
      child: InkWell(
        onTap: () => setState(() => _selected = selected ? null : date),
        borderRadius: BorderRadius.circular(12),
        child: ExcludeSemantics(child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.hover),
          curve: AppMotion.standard,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 4),
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: selected ? c.textPrimary : Colors.transparent,
            border: Border.all(
              color: today && !selected ? c.primary : Colors.transparent, width: 1.5),
            borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, children: [
            Text('$day', style: AppTypography.numeric(size: 13,
              weight: today || list.isNotEmpty ? FontWeight.w700 : FontWeight.w400,
              color: selected ? c.surface : c.textPrimary)),
            const SizedBox(height: 4),
            SizedBox(height: 6, child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (final e in list.take(3))
                Container(width: 6, height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: selected ? c.surface : billTone(e, c))),
            ])),
          ]),
        )),
      ),
    );
  }
}

Color billTone(BillEvent e, AppColors c) =>
    e.neutral ? c.transfer : e.income ? c.income : c.expense;

/// One expected movement, with how soon it is due spelled out.
class BillEventRow extends StatelessWidget {
  const BillEventRow({super.key, required this.event, required this.today,
    this.showDate = false});
  final BillEvent event;
  final DateTime today;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final late = event.date.isBefore(dayOf(today));
    final soon = !late && event.date.difference(dayOf(today)).inDays <= 1;
    final kind = switch (event.source) {
      BillSource.recurring => event.automatic ? 'Tercatat otomatis' : 'Perlu dicatat',
      BillSource.debt => event.income ? 'Piutang' : 'Utang',
      BillSource.account => 'Kartu / PayLater',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: Icon(
          switch (event.source) {
            BillSource.recurring => Icons.event_repeat_rounded,
            BillSource.debt => Icons.handshake_outlined,
            BillSource.account => Icons.credit_card_rounded,
          }, size: 18, color: billTone(event, c))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text.rich(TextSpan(children: [
              if (showDate) TextSpan(
                text: '${DateFormat('d MMM', 'id_ID').format(event.date)} · '),
              TextSpan(text: dueLabel(event.date, today), style: TextStyle(
                fontWeight: late || soon ? FontWeight.w700 : FontWeight.w400,
                color: late ? c.danger : soon ? c.warning : c.textSecondary)),
              TextSpan(text: ' · $kind'),
            ]), style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ])),
        const SizedBox(width: 8),
        if (event.amount != null)
          Text('${event.income ? '+' : event.neutral ? '' : '−'}${event.amount!.rupiah}',
            style: AppTypography.numeric(size: 13, weight: FontWeight.w600,
              color: c.textPrimary)),
      ]),
    );
  }
}

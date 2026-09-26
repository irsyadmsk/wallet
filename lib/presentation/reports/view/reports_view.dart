import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/app/app_events.dart';
import 'package:financial_recording/data/services/financial_health_service.dart';
import 'package:financial_recording/data/services/smart_report_service.dart';
import 'package:financial_recording/presentation/reports/controller/reports_controller.dart';
import 'package:financial_recording/shared/responsive/adaptive_grid.dart';
import 'package:financial_recording/shared/responsive/breakpoints.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/shared/theme/chart_palette.dart';
import 'package:financial_recording/shared/widget/health_score_card.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';
import 'package:financial_recording/shared/widget/section_card.dart';
import 'package:financial_recording/util/money/money_format.dart';

String _periodLabel(CategoryPeriod p) {
  switch (p) {
    case CategoryPeriod.week:
      return 'Minggu ini';
    case CategoryPeriod.month:
      return 'Bulan ini';
    case CategoryPeriod.year:
      return 'Tahun ini';
    case CategoryPeriod.custom:
      return 'Rentang custom';
  }
}

enum _Tab { smart, trend }

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  _Tab _tab = _Tab.smart;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _service = SmartReportService();

  bool get _isThisMonth {
    final n = DateTime.now();
    return _month.year == n.year && _month.month == n.month;
  }

  void _shift(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    Get.put(ReportsController(), tag: 'reports');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Laporan'),
        actions: [
          if (_tab == _Tab.smart)
            WIconButton(
              icon: Icons.ios_share_rounded,
              tooltip: 'Salin laporan sebagai teks',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _service.forMonth(_month).toShareText()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Laporan disalin. Tempel di WhatsApp, catatan, atau email.')),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: ContentShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: PillTabs<_Tab>(
                  tabs: const [
                    PillTab(_Tab.smart, 'Ringkasan cerdas', icon: Icons.auto_awesome_outlined),
                    PillTab(_Tab.trend, 'Tren & komposisi', icon: Icons.show_chart_rounded),
                  ],
                  value: _tab,
                  onChanged: (t) => setState(() => _tab = t),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.base),
                switchInCurve: AppMotion.emphasized,
                child: _tab == _Tab.smart
                    ? Obx(() {
                        dataVersion.value;
                        return _SmartTab(
                          key: ValueKey(_month),
                          report: _service.forMonth(_month),
                          canNext: !_isThisMonth,
                          onPrev: () => _shift(-1),
                          onNext: () => _shift(1),
                        );
                      })
                    : const _TrendTab(key: ValueKey('trend')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartTab extends StatelessWidget {
  const _SmartTab({super.key, required this.report, required this.canNext, required this.onPrev, required this.onNext});
  final SmartReport report;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final r = report;
    final wide = !context.isCompact;
    var i = 0;

    final left = <Widget>[
      if (!r.isEmpty)
        Reveal(
          index: i++,
          child: _Ledger(report: r),
        ),
      if (r.isCurrentMonth && r.expense > 0 && r.daysElapsed < r.daysInMonth) ...[
        const SizedBox(height: 16),
        Reveal(
          index: i++,
          child: _Projection(report: r),
        ),
      ],
      const SizedBox(height: 16),
      Reveal(
        index: i++,
        child: SectionCard(
          title: 'Ringkasan',
          child: Column(children: [for (final n in r.narrative) _NoteRow(note: n)]),
        ),
      ),
      if (r.actions.isNotEmpty) ...[
        const SizedBox(height: 16),
        Reveal(
          index: i++,
          child: SectionCard(
            title: 'Langkah berikutnya',
            child: Column(children: [for (final n in r.actions) _NoteRow(note: n, action: true)]),
          ),
        ),
      ],
      // Moved here from the dashboard, which now shows only today's numbers.
      if (r.isCurrentMonth) ...[
        const SizedBox(height: 16),
        Reveal(
          index: i++,
          child: HealthScoreCard(report: FinancialHealthService().calculateReport()),
        ),
      ],
    ];

    final right = <Widget>[
      if (r.categories.isNotEmpty)
        Reveal(
          index: i++,
          child: SectionCard(
            title: 'Ke mana uang pergi',
            child: _CategoryBars(report: r),
          ),
        ),
      if (r.expense > 0) ...[
        const SizedBox(height: 16),
        Reveal(
          index: i++,
          child: SectionCard(
            title: 'Pola belanja per hari',
            child: _WeekdayBars(values: r.weekdaySpend),
          ),
        ),
      ],
      if (r.members.length > 1) ...[
        const SizedBox(height: 16),
        Reveal(
          index: i++,
          child: SectionCard(
            title: 'Per anggota keluarga',
            child: Column(
              children: [
                for (final m in r.members)
                  _KeyValueRow(label: m.name, sub: '${m.count} transaksi', value: m.expense.rupiah),
              ],
            ),
          ),
        ),
      ],
      if (r.subscriptions.isNotEmpty) ...[
        const SizedBox(height: 16),
        Reveal(
          index: i++,
          child: SectionCard(
            title: 'Pembayaran rutin terdeteksi',
            child: Column(
              children: [
                for (final s in r.subscriptions)
                  _KeyValueRow(
                    label: s.label,
                    sub: 'muncul ${s.months} dari 4 bulan terakhir',
                    value: '${s.monthlyAmount.rupiah}/bln',
                  ),
              ],
            ),
          ),
        ),
      ],
      if (r.payees.isNotEmpty) ...[
        const SizedBox(height: 16),
        Reveal(
          index: i++,
          child: SectionCard(
            title: 'Tujuan belanja teratas',
            child: Column(
              children: [
                for (final p in r.payees)
                  _KeyValueRow(label: p.label, sub: '${p.count}× transaksi', value: p.amount.rupiah),
              ],
            ),
          ),
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            WIconButton(icon: Icons.chevron_left_rounded, tooltip: 'Bulan sebelumnya', filled: true, onPressed: onPrev),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: DateFormat('MMMM ', 'id_ID').format(r.month), style: t.headlineMedium),
                    TextSpan(
                      text: DateFormat('y').format(r.month),
                      style: AppTypography.serif(size: 28, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            WIconButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Bulan berikutnya',
              filled: true,
              onPressed: canNext ? onNext : null,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (r.isEmpty)
          const _EmptyReport()
        else if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right),
              ),
            ],
          )
        else ...[
          ...left,
          const SizedBox(height: 16),
          ...right,
        ],
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, size: 32, color: c.textTertiary),
          const SizedBox(height: 12),
          Text('Belum ada transaksi di bulan ini', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Laporan tersusun otomatis begitu transaksi pertama dicatat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Four headline figures in one hairline-divided ledger row.
class _Ledger extends StatelessWidget {
  const _Ledger({required this.report});
  final SmartReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = report;
    (bool, String)? delta(double? v) {
      if (v == null || v.abs() < 0.005) return null;
      return (v >= 0, '${(v.abs() * 100).toStringAsFixed(0)}% vs bln lalu');
    }

    final cells = <(String, String, (bool, String)?)>[
      ('Pemasukan', r.income.rupiah, delta(r.incomeChange)),
      ('Pengeluaran', r.expense.rupiah, delta(r.expenseChange)),
      ('Selisih', r.net.signedRupiah, null),
      ('Rasio tabungan', r.savingsRate == null ? '—' : '${(r.savingsRate! * 100).toStringAsFixed(0)}%', null),
    ];
    return Card(
      child: LayoutBuilder(
        builder: (context, box) {
          final cols = box.maxWidth >= 520 ? 4 : 2;
          final w = box.maxWidth / cols;
          return Wrap(
            children: [
              for (var i = 0; i < cells.length; i++)
                Container(
                  width: w,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border(
                      left: i % cols == 0 ? BorderSide.none : BorderSide(color: c.border),
                      top: i < cols ? BorderSide.none : BorderSide(color: c.border),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cells[i].$1, style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          cells[i].$2,
                          style: AppTypography.numeric(size: 20, weight: FontWeight.w600, color: c.textPrimary),
                        ),
                      ),
                      if (cells[i].$3 case (final up, final text)) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              size: 12,
                              color: c.textTertiary,
                            ),
                            const SizedBox(width: 2),
                            Flexible(child: Text(text, style: TextStyle(fontSize: 11.5, color: c.textTertiary))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Spent-so-far vs. projected month-end vs. income, on one track.
class _Projection extends StatelessWidget {
  const _Projection({required this.report});
  final SmartReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = report;
    final scale = [r.projectedExpense, r.income, r.expense].reduce((a, b) => a > b ? a : b).toDouble();
    final over = r.income > 0 && r.projectedExpense > r.income;
    double f(int v) => scale <= 0 ? 0 : (v / scale).clamp(0, 1).toDouble();

    return SectionCard(
      title: 'Perkiraan akhir bulan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                r.projectedExpense.rupiah,
                style: AppTypography.numeric(size: 26, weight: FontWeight.w600, color: c.textPrimary),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'hari ke-${r.daysElapsed} dari ${r.daysInMonth}',
                  style: TextStyle(color: c.textSecondary, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              return SizedBox(
                height: 34,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 8,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: f(r.projectedExpense)),
                      duration: AppMotion.of(context, const Duration(milliseconds: 900)),
                      curve: AppMotion.emphasized,
                      builder: (_, v, _) => Positioned(
                        left: 0,
                        top: 8,
                        width: w * v,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: (over ? c.expense : c.textPrimary).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: f(r.expense)),
                      duration: AppMotion.of(context, const Duration(milliseconds: 900)),
                      curve: AppMotion.emphasized,
                      builder: (_, v, _) => Positioned(
                        left: 0,
                        top: 8,
                        width: w * v,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: over ? c.expense : c.textPrimary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    if (r.income > 0)
                      Positioned(
                        left: (w * f(r.income) - 1).clamp(0, w - 2),
                        top: 0,
                        child: Container(width: 2, height: 26, color: c.success),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Legend(color: over ? c.expense : c.textPrimary, label: 'Sudah keluar ${r.expense.rupiah}'),
              _Legend(color: (over ? c.expense : c.textPrimary).withValues(alpha: 0.25), label: 'Proyeksi'),
              if (r.income > 0) _Legend(color: c.success, label: 'Pemasukan ${r.income.rupiah}', line: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.line = false});
  final Color color;
  final String label;
  final bool line;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: line ? 2 : 10,
        height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
    ],
  );
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, this.action = false});
  final ReportNote note;
  final bool action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, color, label) = switch (note.tone) {
      InsightTone.good => (Icons.check_circle_outline_rounded, c.success, 'Baik'),
      InsightTone.warning => (Icons.error_outline_rounded, c.warning, 'Perhatian'),
      InsightTone.neutral => (action ? Icons.arrow_forward_rounded : Icons.circle_outlined, c.textTertiary, 'Info'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: label,
            child: Icon(icon, size: note.tone == InsightTone.neutral && !action ? 10 : 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(note.text, style: const TextStyle(height: 1.45, fontSize: 14.5))),
        ],
      ),
    );
  }
}

/// Categories as single-hue magnitude bars; a spike gets an icon + label,
/// never colour alone.
class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.report});
  final SmartReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = report.categories.take(7).toList();
    final max = top.first.amount.toDouble();
    return Column(
      children: [
        for (var i = 0; i < top.length; i++)
          Tooltip(
            message:
                '${top[i].name}: ${top[i].amount.rupiah} · ${top[i].count} transaksi'
                '${top[i].average3 > 0 ? ' · rata-rata 3 bln ${top[i].average3.rupiah}' : ''}',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          top[i].name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (top[i].isSpike) ...[
                        Icon(Icons.trending_up_rounded, size: 16, color: c.warning),
                        const SizedBox(width: 4),
                        Text(
                          'Melonjak',
                          style: TextStyle(fontSize: 11.5, color: c.warning, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        top[i].amount.rupiah,
                        style: AppTypography.numeric(size: 13.5, weight: FontWeight.w600, color: c.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, box) => TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: top[i].amount / max),
                      duration: AppMotion.of(context, Duration(milliseconds: 700 + 60 * i)),
                      curve: AppMotion.emphasized,
                      builder: (_, v, _) => Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: (box.maxWidth * v).clamp(4, box.maxWidth),
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == 0 ? c.textPrimary : c.textPrimary.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(top[i].share * 100).toStringAsFixed(0)}% dari belanja'
                    '${(top[i].changeVsAverage?.abs() ?? 0) < 0.05 ? '' : ' · ${top[i].changeVsAverage! >= 0 ? '+' : '−'}${(top[i].changeVsAverage!.abs() * 100).toStringAsFixed(0)}% vs rata-rata 3 bln'}',
                    style: TextStyle(fontSize: 11.5, color: c.textTertiary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekdayBars extends StatelessWidget {
  const _WeekdayBars({required this.values});
  final List<int> values;

  static const _labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final max = values.reduce((a, b) => a > b ? a : b);
    final peak = values.indexOf(max);
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Tooltip(
                message: '${_labels[i]}: ${values[i].rupiah}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (i == peak && max > 0)
                        Text(
                          values[i].compact,
                          style: AppTypography.numeric(size: 11, weight: FontWeight.w600, color: c.textPrimary),
                        ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: max == 0 ? 0 : values[i] / max),
                        duration: AppMotion.of(context, Duration(milliseconds: 600 + 50 * i)),
                        curve: AppMotion.emphasized,
                        builder: (_, v, _) => Container(
                          height: (100 * v).clamp(3, 100),
                          decoration: BoxDecoration(
                            color: i == peak ? c.textPrimary : c.textPrimary.withValues(alpha: 0.3),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _labels[i],
                        style: TextStyle(fontSize: 11.5, color: i == peak ? c.textPrimary : c.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value, this.sub});
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (sub != null) Text(sub!, style: TextStyle(fontSize: 12, color: c.textTertiary)),
              ],
            ),
          ),
          Text(
            value,
            style: AppTypography.numeric(size: 13.5, weight: FontWeight.w600, color: c.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// The earlier multi-month charts, unchanged in substance.
class _TrendTab extends StatelessWidget {
  const _TrendTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ReportsController>(tag: 'reports');
    final colors = context.colors;
    return Obx(() {
      dataVersion.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PillTabs<int>(
            dense: true,
            tabs: const [PillTab(3, '3 bulan'), PillTab(6, '6 bulan'), PillTab(12, '12 bulan')],
            value: c.monthsBack.value,
            onChanged: c.setMonthsBack,
          ),
          const SizedBox(height: AppSpacing.lg),
          AdaptiveGrid(
            columnsOverride: context.isCompact ? 1 : 2,
            children: [
              _StatCard(label: 'Total pemasukan', value: c.periodIncome.value, color: colors.income),
              _StatCard(label: 'Total pengeluaran', value: c.periodExpense.value, color: colors.expense),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'Arus kas per bulan',
            trailing: Wrap(
              spacing: 12,
              children: [
                _Legend(color: colors.income, label: 'Pemasukan'),
                _Legend(color: colors.expense, label: 'Pengeluaran'),
              ],
            ),
            child: SizedBox(
              height: 220,
              child: c.monthly.isEmpty ? const SizedBox() : _CashflowChart(points: c.monthly),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'Tren kekayaan bersih',
            child: SizedBox(
              height: 200,
              child: c.netWorthHistory.isEmpty ? const SizedBox() : _NetWorthChart(points: c.netWorthHistory),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'Pengeluaran per kategori',
            trailing: PopupMenuButton<CategoryPeriod>(
              tooltip: 'Pilih periode',
              initialValue: c.categoryPeriod.value,
              onSelected: (p) async {
                if (p == CategoryPeriod.custom) {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: DateTimeRange(start: c.categoryCustomFrom.value, end: c.categoryCustomTo.value),
                  );
                  if (range != null) {
                    c.setCategoryCustomRange(range.start, range.end);
                  }
                } else {
                  c.setCategoryPeriod(p);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: CategoryPeriod.week, child: Text('Minggu ini')),
                PopupMenuItem(value: CategoryPeriod.month, child: Text('Bulan ini')),
                PopupMenuItem(value: CategoryPeriod.year, child: Text('Tahun ini')),
                PopupMenuItem(value: CategoryPeriod.custom, child: Text('Pilih rentang…')),
              ],
              child: Chip(
                label: Text(_periodLabel(c.categoryPeriod.value)),
                avatar: const Icon(Icons.expand_more_rounded, size: 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Total: ${c.categoryPeriodTotal.value.rupiah}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                c.expenseByCategory.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text('Belum ada pengeluaran pada periode ini.'),
                      )
                    : _CategoryBreakdown(slices: c.expenseByCategory),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AdaptiveGrid(
            columnsOverride: context.isCompact ? 1 : 2,
            children: [
              SectionCard(
                title: 'Komposisi aset',
                child: c.assetComposition.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text('Belum ada aset.', style: TextStyle(color: colors.textSecondary)),
                      )
                    : _CategoryBreakdown(slices: c.assetComposition),
              ),
              SectionCard(
                title: 'Komposisi liabilitas',
                child: c.liabilityComposition.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text('Tidak ada utang/liabilitas aktif.', style: TextStyle(color: colors.textSecondary)),
                      )
                    : _CategoryBreakdown(slices: c.liabilityComposition),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value.rupiah,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _CashflowChart extends StatelessWidget {
  const _CashflowChart({required this.points});
  final List<MonthPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxY = points.fold<int>(0, (m, p) => [m, p.income, p.expense].reduce((a, b) => a > b ? a : b)).toDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY <= 0 ? 1 : maxY / 4),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, meta) =>
                  Text(v.toInt().compact, style: TextStyle(fontSize: 10, color: colors.textTertiary)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i < 0 || i >= points.length || (v - i).abs() > 0.01) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('MMM', 'id_ID').format(points[i].month),
                    style: TextStyle(fontSize: 10, color: colors.textTertiary),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: colors.income,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].income.toDouble())],
          ),
          LineChartBarData(
            isCurved: true,
            color: colors.expense,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].expense.toDouble())],
          ),
        ],
      ),
    );
  }
}

class _NetWorthChart extends StatelessWidget {
  const _NetWorthChart({required this.points});
  final List<NetWorthPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final values = points.map((p) => p.netWorth).toList();
    final minY = values.reduce((a, b) => a < b ? a : b).toDouble();
    final maxY = values.reduce((a, b) => a > b ? a : b).toDouble();
    final pad = (maxY - minY).abs() * 0.15;
    final trendUp = values.last >= values.first;
    final lineColor = trendUp ? colors.income : colors.expense;

    return LineChart(
      LineChartData(
        minY: minY - (pad == 0 ? 1 : pad),
        maxY: maxY + (pad == 0 ? 1 : pad),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY).abs() / 4 == 0 ? 1 : (maxY - minY).abs() / 4,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, meta) =>
                  Text(v.toInt().compact, style: TextStyle(fontSize: 10, color: colors.textTertiary)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i < 0 || i >= points.length || (v - i).abs() > 0.01) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('MMM', 'id_ID').format(points[i].month),
                    style: TextStyle(fontSize: 10, color: colors.textTertiary),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: lineColor.withValues(alpha: 0.12)),
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].netWorth.toDouble())],
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.slices});
  final List<CategorySlice> slices;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<int>(0, (s, e) => s + e.amount);
    final colors = context.colors;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: [
                for (final s in slices)
                  PieChartSectionData(
                    value: s.amount.toDouble(),
                    color: ChartPalette.of(context, s.slot),
                    title: '',
                    radius: 42,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final s in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(radius: 5, backgroundColor: ChartPalette.of(context, s.slot)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(
                  '${(total == 0 ? 0 : s.amount / total * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(s.amount.rupiah, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}

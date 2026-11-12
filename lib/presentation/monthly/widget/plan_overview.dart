import 'package:flutter/material.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/presentation/monthly/widget/plan_kind.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';

/// Read-only summary of one plan document: what is available, how much is
/// allocated, and where it flows. Every figure comes from [plan]; no ledger
/// data is read or written here.
class PlanOverview extends StatelessWidget {
  const PlanOverview({
    super.key,
    required this.plan,
    required this.money,
    required this.selected,
    required this.onSelect,
    required this.onEditIncome,
  });

  final MonthlyPlan plan;
  final String Function(int) money;
  final PlanKind? selected;
  final ValueChanged<PlanKind?> onSelect;
  final VoidCallback? onEditIncome;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final available = plan.available, planned = plan.planned;
    final left = plan.unallocated, deficit = left < 0;
    final share = available <= 0 ? 0.0 : planned / available;
    final source = plan.received != null
        ? 'Diterima ${money(plan.received!)}'
        : 'Bruto ${money(plan.gross)} − potongan ${money(plan.deductions)}';

    final hero = _Card(
      color: c.textPrimary,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Dana tersedia',
          style: TextStyle(fontSize: 13, color: c.surface.withValues(alpha: .78))),
        const SizedBox(height: 6),
        _Amount(value: available, size: 30, color: c.surface),
        const SizedBox(height: 6),
        Text(plan.bonus > 0 ? '$source + bonus ${money(plan.bonus)}' : source,
          style: TextStyle(fontSize: 12, color: c.surface.withValues(alpha: .78))),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onEditIncome,
          style: TextButton.styleFrom(
            foregroundColor: c.surface,
            disabledForegroundColor: c.surface.withValues(alpha: .5),
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            alignment: AlignmentDirectional.centerStart),
          child: const Text('Ubah pendapatan'),
        ),
      ]),
    );
    final allocated = _Card(
      color: c.surface, border: c.border,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Teralokasi', style: TextStyle(fontSize: 13, color: c.textSecondary)),
        const SizedBox(height: 6),
        _Amount(value: planned, size: 24, color: c.textPrimary),
        const SizedBox(height: 12),
        AnimatedProgress(value: share, color: deficit ? c.danger : c.primary,
          track: c.surfaceAlt, semanticsLabel: 'Bagian dana yang teralokasi'),
        const SizedBox(height: 10),
        Text('${(share * 100).toStringAsFixed(1).replaceAll('.', ',')}% dari dana tersedia',
          style: TextStyle(fontSize: 12, color: c.textSecondary)),
        const SizedBox(height: 2),
        Text('Aktual tercatat ${money(plan.actual)}',
          style: TextStyle(fontSize: 12, color: c.textSecondary)),
      ]),
    );
    final rest = _Card(
      color: c.surface, border: c.border,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(deficit ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 16, color: deficit ? c.danger : c.primary),
          const SizedBox(width: 6),
          Flexible(child: Text(deficit ? 'Defisit' : 'Belum dialokasikan',
            style: TextStyle(fontSize: 13, color: c.textSecondary))),
        ]),
        const SizedBox(height: 6),
        _Amount(value: left.abs(), size: 24, color: deficit ? c.danger : c.primary),
        const SizedBox(height: 12),
        Text(deficit
            ? 'Alokasi melebihi dana tersedia. Kurangi pos atau perbarui pendapatan.'
            : 'Langganan ${money(plan.digital)} per bulan termasuk dalam alokasi.',
          style: TextStyle(fontSize: 12, color: c.textSecondary)),
      ]),
    );

    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 760;
      final narrow = box.maxWidth < 420 ||
          MediaQuery.textScalerOf(context).scale(14) > 18;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (wide)
          IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: hero), const SizedBox(width: 12),
              Expanded(flex: 4, child: allocated), const SizedBox(width: 12),
              Expanded(flex: 4, child: rest),
            ]))
        else ...[
          hero, const SizedBox(height: 12),
          if (narrow) ...[allocated, const SizedBox(height: 12), rest]
          else IntrinsicHeight(child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: allocated), const SizedBox(width: 12),
              Expanded(child: rest),
            ])),
        ],
        const SizedBox(height: 12),
        _FlowCard(plan: plan, money: money, selected: selected, onSelect: onSelect),
      ]);
    });
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.color, required this.child, this.border});
  final Color color;
  final Color? border;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: color,
      border: border == null ? null : Border.all(color: border!),
      borderRadius: BorderRadius.circular(24)),
    child: child);
}

class _Amount extends StatelessWidget {
  const _Amount({required this.value, required this.size, required this.color});
  final int value;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart,
    child: AnimatedMoney(value: value,
      style: AppTypography.numeric(size: size, weight: FontWeight.w700, color: color)));
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({required this.plan, required this.money,
    required this.selected, required this.onSelect});
  final MonthlyPlan plan;
  final String Function(int) money;
  final PlanKind? selected;
  final ValueChanged<PlanKind?> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final totals = planTotals(plan);
    final left = plan.unallocated > 0 ? plan.unallocated : 0;
    final whole = plan.planned + left;
    double part(int v) => whole <= 0 ? 0 : v / whole;
    String percent(int v) =>
        '${(part(v) * 100).toStringAsFixed(1).replaceAll('.', ',')}%';
    final summary = [
      for (final k in PlanKind.values) '${k.label} ${percent(totals[k]!)}',
      'sisa ${percent(left)}',
    ].join(', ');
    return _Card(
      color: c.surface, border: c.border,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Arus alokasi', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Pilih satu bagian untuk menyaring daftar pos.',
          style: TextStyle(fontSize: 12, color: c.textSecondary)),
        const SizedBox(height: 16),
        Semantics(
          label: 'Pembagian dana: $summary',
          child: ExcludeSemantics(child: _FlowBar(
            fractions: [for (final k in PlanKind.values) part(totals[k]!), part(left)],
            colors: [for (final k in PlanKind.values) k.color(c), c.border],
            dim: [for (final k in PlanKind.values) selected != null && selected != k,
              selected != null],
          )),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final k in PlanKind.values)
            _Legend(
              label: k.label, color: k.color(c),
              detail: '${money(totals[k]!)} · ${percent(totals[k]!)}',
              selected: selected == k,
              onTap: () => onSelect(selected == k ? null : k)),
          _Legend(label: 'Sisa', color: c.border,
            detail: '${money(left)} · ${percent(left)}'),
        ]),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.color, required this.detail,
    this.selected = false, this.onTap});
  final String label, detail;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final body = AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.hover),
      curve: AppMotion.standard,
      constraints: const BoxConstraints(minHeight: 52, minWidth: 136),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: onTap == null ? c.surfaceAlt
            : selected ? c.primaryContainer : c.surface,
        border: Border.all(width: 1.5, color: onTap == null ? c.surfaceAlt
            : selected ? c.textPrimary : c.border),
        borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w600, color: c.textPrimary))),
          ]),
          const SizedBox(height: 3),
          Text(detail, style: AppTypography.numeric(size: 12,
            weight: FontWeight.w500, color: c.textSecondary)),
        ]),
    );
    if (onTap == null) return body;
    return Semantics(
      button: true, selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
          child: body)),
    );
  }
}

/// Five fixed slots animated together, so the bar never overflows while its
/// proportions change. Grows in from empty on first build.
class _FlowBar extends StatefulWidget {
  const _FlowBar({required this.fractions, required this.colors, required this.dim});
  final List<double> fractions;
  final List<Color> colors;
  final List<bool> dim;
  @override
  State<_FlowBar> createState() => _FlowBarState();
}

class _FlowBarState extends State<_FlowBar> with SingleTickerProviderStateMixin {
  late final AnimationController _run =
      AnimationController(vsync: this, duration: AppMotion.reveal);
  late List<double> _from = List.filled(widget.fractions.length * 2, 0.0);
  late List<double> _to = _target();

  List<double> _target() => [
    ...widget.fractions,
    for (final d in widget.dim) d ? .25 : 1.0,
  ];

  List<double> _now() {
    final t = AppMotion.emphasized.transform(_run.value);
    return [for (var i = 0; i < _to.length; i++) _from[i] + (_to[i] - _from[i]) * t];
  }

  void _start() {
    if (AppMotion.reduced(context)) {
      _run.value = 1;
    } else {
      _run.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_run.value == 0 && !_run.isAnimating) _start();
  }

  @override
  void didUpdateWidget(_FlowBar old) {
    super.didUpdateWidget(old);
    final next = _target();
    var same = true;
    for (var i = 0; i < next.length; i++) {
      if (next[i] != _to[i]) same = false;
    }
    if (same) return;
    _from = _now();
    _to = next;
    _start();
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 20,
    child: AnimatedBuilder(
      animation: _run,
      builder: (context, _) => CustomPaint(
        painter: _FlowPainter(_now(), widget.colors, Directionality.of(context)),
        child: const SizedBox.expand()),
    ),
  );
}

class _FlowPainter extends CustomPainter {
  _FlowPainter(this.values, this.colors, this.dir);
  final List<double> values;
  final List<Color> colors;
  final TextDirection dir;

  @override
  void paint(Canvas canvas, Size size) {
    final n = colors.length;
    const gap = 3.0;
    final shown = [for (var i = 0; i < n; i++) if (values[i] > 0.0005) i];
    if (shown.isEmpty) return;
    final room = size.width - gap * (shown.length - 1);
    if (room <= 0) return;
    final total = shown.fold(0.0, (s, i) => s + values[i]);
    var x = 0.0;
    for (final i in shown) {
      final w = room * values[i] / (total < 1 ? 1 : total);
      final left = dir == TextDirection.ltr ? x : size.width - x - w;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left, 0, w, size.height),
          Radius.circular(w < 12 ? w / 2 : 6)),
        Paint()..color = colors[i].withValues(alpha: values[n + i].clamp(0.0, 1.0)));
      x += w + gap;
    }
  }

  @override
  bool shouldRepaint(_FlowPainter old) => true;
}

import 'package:flutter/material.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/presentation/monthly/widget/plan_kind.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';

/// One allocation row. Ticking it only marks the plan; it never posts a
/// transaction (see DESIGN.md, "One Wallet planner").
class PlanItemTile extends StatelessWidget {
  const PlanItemTile({
    super.key,
    required this.item,
    required this.money,
    required this.onToggle,
    required this.onEdit,
  });

  final AllocationItem item;
  final String Function(int) money;
  final ValueChanged<bool?>? onToggle;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final kind = planKindOf(item);
    final rule = item.rule;
    final caption = switch (kind) {
      PlanKind.subscription =>
        '${rule!.enabled ? "Langganan aktif" : "Dijeda dalam rencana"} · '
        '${rule.months == 12 ? "cadangan tahunan ÷ 12" : "bulanan"} · '
        'pajak ${rule.taxIncluded ? "termasuk" : "${_percent(rule.taxBps)}%"}',
      PlanKind.saving =>
        'Tabungan otomatis · prioritas ${rule!.priority} · porsi ${rule.weight}',
      PlanKind.fund => 'Dana bergulir',
      PlanKind.fixed => 'Pos tetap',
      null => 'Potongan gaji',
    };
    final tone = kind?.color(c) ?? c.textTertiary;
    final amount = Text(money(item.amount),
      style: AppTypography.numeric(size: 15, weight: FontWeight.w600,
        color: c.textPrimary));

    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 600;
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 48, height: 48, child: Checkbox(
          semanticLabel: 'Selesai: ${item.name}',
          value: item.done, onChanged: onToggle)),
        Expanded(child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 12, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedDefaultTextStyle(
              duration: AppMotion.of(context, AppMotion.base),
              curve: AppMotion.standard,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: item.done ? c.textSecondary : c.textPrimary,
                decoration: item.done ? TextDecoration.lineThrough : null,
                decorationColor: c.textSecondary),
              child: Text(item.name)),
            if (!wide) Padding(padding: const EdgeInsets.only(top: 5), child: amount),
            Padding(padding: const EdgeInsets.only(top: 6), child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 2),
                  child: Icon(kind?.icon ?? Icons.remove_circle_outline,
                    size: 14, color: tone)),
                const SizedBox(width: 6),
                Expanded(child: Text(caption,
                  style: TextStyle(color: c.textSecondary, fontSize: 12))),
              ])),
            if (kind == PlanKind.saving && item.amount > 0 && rule!.enabled)
              Padding(padding: const EdgeInsets.only(top: 8), child: _SavingSplit(
                item: item, money: money)),
            if (item.actual != null)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text(
                'Aktual ${money(item.actual!)}',
                style: TextStyle(color: c.textSecondary, fontSize: 12))),
            if (item.rollover)
              Padding(padding: const EdgeInsets.only(top: 8), child: _FundBalance(
                item: item, money: money)),
            if (item.note.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text(item.note,
                style: TextStyle(color: c.textSecondary, fontSize: 13))),
          ]),
        )),
        if (wide) SizedBox(width: 150, child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 13, 12, 12),
          child: Align(alignment: AlignmentDirectional.centerEnd, child: amount))),
        SizedBox(width: 48, height: 48, child: IconButton(
          tooltip: 'Ubah ${item.name}', onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined))),
      ]);
    });
  }
}

/// Basis points as an Indonesian percentage: 1100 → "11", 1150 → "11,5".
String _percent(int bps) => bps % 100 == 0
    ? '${bps ~/ 100}'
    : (bps / 100).toString().replaceAll('.', ',');

/// Base target first, then the weighted share of what is left.
class _SavingSplit extends StatelessWidget {
  const _SavingSplit({required this.item, required this.money});
  final AllocationItem item;
  final String Function(int) money;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = item.amount < item.rule!.target ? item.amount : item.rule!.target;
    final extra = item.amount - base;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedProgress(value: base / item.amount, secondary: extra / item.amount,
        color: c.primary, secondaryColor: Color.lerp(c.primary, c.surface, .55),
        track: c.surfaceAlt, height: 6,
        semanticsLabel: 'Bagian target dasar dan surplus'),
      const SizedBox(height: 5),
      Text('Dasar ${money(base)} + surplus ${money(extra)}',
        style: TextStyle(color: c.textSecondary, fontSize: 12)),
    ]);
  }
}

class _FundBalance extends StatelessWidget {
  const _FundBalance({required this.item, required this.money});
  final AllocationItem item;
  final String Function(int) money;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pool = item.opening + (item.actual ?? 0);
    final negative = item.balance < 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedProgress(value: pool <= 0 ? (item.spent > 0 ? 1 : 0) : item.spent / pool,
        color: negative ? c.danger : c.warning, track: c.surfaceAlt, height: 6,
        semanticsLabel: 'Dana terpakai'),
      const SizedBox(height: 5),
      Text('Saldo dana ${money(item.balance)} · dibawa ke bulan berikutnya',
        style: TextStyle(fontSize: 12,
          color: negative ? c.danger : c.textSecondary,
          fontWeight: FontWeight.w600)),
      if (item.spent > 0 || item.opening != 0)
        Text('Awal ${money(item.opening)} · terpakai ${money(item.spent)}',
          style: TextStyle(color: c.textSecondary, fontSize: 12)),
    ]);
  }
}

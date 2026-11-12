import 'package:flutter/material.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';

/// Presentation-only grouping of plan items. Derived from the stored rule and
/// rollover flag; nothing here is persisted.
enum PlanKind { fixed, subscription, saving, fund }

extension PlanKindView on PlanKind {
  String get label => switch (this) {
    PlanKind.fixed => 'Tetap',
    PlanKind.subscription => 'Langganan',
    PlanKind.saving => 'Tabungan otomatis',
    PlanKind.fund => 'Dana bergulir',
  };

  IconData get icon => switch (this) {
    PlanKind.fixed => Icons.push_pin_outlined,
    PlanKind.subscription => Icons.autorenew_rounded,
    PlanKind.saving => Icons.savings_outlined,
    PlanKind.fund => Icons.sync_alt_rounded,
  };

  /// Segments differ in lightness as well as hue, so they stay distinct
  /// without relying on colour vision.
  Color color(AppColors c) => switch (this) {
    PlanKind.fixed => c.primary,
    PlanKind.subscription => c.textPrimary,
    PlanKind.saving => Color.lerp(c.primary, c.surface, .5)!,
    PlanKind.fund => c.warning,
  };
}

/// Salary deductions are not allocations and have no kind.
PlanKind? planKindOf(AllocationItem item) {
  if (item.group == 'Potongan gaji') return null;
  if (item.rule?.kind == 'subscription') return PlanKind.subscription;
  if (item.rule?.kind == 'saving') return PlanKind.saving;
  if (item.rollover) return PlanKind.fund;
  return PlanKind.fixed;
}

Map<PlanKind, int> planTotals(MonthlyPlan plan) {
  final totals = {for (final k in PlanKind.values) k: 0};
  for (final item in plan.items) {
    final kind = planKindOf(item);
    if (kind != null) totals[kind] = totals[kind]! + item.amount;
  }
  return totals;
}

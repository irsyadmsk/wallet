import 'package:flutter/material.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';

/// Ledger totals only: these cards never infer savings from account balances.
/// Use available content width, including when the desktop sidebar is open.
class WalletFlowCards extends StatelessWidget {
  const WalletFlowCards({
    super.key,
    required this.income,
    required this.expense,
    this.hidden = false,
  });

  final int income, expense;
  final bool hidden;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stack = constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(14) > 18;
      final cards = [
        _FlowCard(label: 'Pemasukan', note: 'Tercatat bulan ini',
          value: income, hidden: hidden, income: true),
        _FlowCard(label: 'Pengeluaran', note: 'Tercatat bulan ini',
          value: expense, hidden: hidden, income: false),
      ];
      if (stack) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [cards.first, const SizedBox(height: 12), cards.last]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: cards.first), const SizedBox(width: 12),
          Expanded(child: cards.last)]);
    },
  );
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({required this.label, required this.note, required this.value,
    required this.hidden, required this.income});
  final String label, note;
  final int value;
  final bool hidden, income;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = income ? c.income : c.expense;
    return Container(
      constraints: const BoxConstraints(minHeight: 192),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: tone.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(income ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 20, color: tone)),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(color: c.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart,
            child: AnimatedMoney(value: value, hidden: hidden,
              style: AppTypography.numeric(size: 22, weight: FontWeight.w600,
                color: c.textPrimary))),
          const SizedBox(height: 8),
          Text(note, style: TextStyle(fontSize: 11, color: c.textSecondary)),
        ]),
    );
  }
}

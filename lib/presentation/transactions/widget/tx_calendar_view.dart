import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/presentation/transactions/controller/transactions_controller.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/util/money/money_format.dart';

/// A month grid with each day's income/expense total, mirroring the
/// "Kalender" tab from Money Manager. Tapping a day filters the transaction
/// list below to just that day via [TransactionsController.setDateRange].
class TxCalendarView extends StatelessWidget {
  const TxCalendarView({super.key, required this.controller});
  final TransactionsController controller;

  static const _weekdays = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final month = controller.calendarMonth.value;
    final totals = controller.calendarDayTotals;
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Sunday-first grid, matching the reference app.
    final leadingBlanks = firstOfMonth.weekday % 7;
    final selectedDay = controller.from.value != null &&
            controller.to.value != null &&
            controller.from.value!.year == month.year &&
            controller.from.value!.month == month.month &&
            controller.to.value!.difference(controller.from.value!).inDays <= 1
        ? controller.from.value!.day
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => controller.shiftCalendarMonth(-1),
            ),
            Text(
              DateFormat('MMMM y', 'id_ID').format(month),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => controller.shiftCalendarMonth(1),
            ),
          ],
        ),
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(
                  child: Text(w, style: TextStyle(fontSize: 11, color: colors.textTertiary, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.78),
          itemCount: leadingBlanks + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox();
            final day = index - leadingBlanks + 1;
            final (income, expense) = totals[day] ?? (0, 0);
            final isSelected = selectedDay == day;
            final isToday = DateTime.now().year == month.year &&
                DateTime.now().month == month.month &&
                DateTime.now().day == day;

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                final d = DateTime(month.year, month.month, day);
                controller.setDateRange(d, DateTime(d.year, d.month, d.day, 23, 59, 59));
              },
              child: Container(
                margin: const EdgeInsets.all(1.5),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primaryContainer : null,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday && !isSelected ? Border.all(color: colors.primary.withValues(alpha: 0.5)) : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? colors.primary : colors.textPrimary,
                      ),
                    ),
                    if (income > 0)
                      Text(income.compact, style: TextStyle(fontSize: 8.5, color: colors.income, fontWeight: FontWeight.w600)),
                    if (expense > 0)
                      Text(expense.compact, style: TextStyle(fontSize: 8.5, color: colors.expense, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          },
        ),
        if (selectedDay != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => controller.setDateRange(null, null),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Hapus filter tanggal'),
              ),
            ),
          ),
      ],
    );
  }
}

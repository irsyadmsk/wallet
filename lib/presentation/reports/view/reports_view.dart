import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/presentation/reports/controller/reports_controller.dart';
import 'package:financial_recording/shared/responsive/adaptive_grid.dart';
import 'package:financial_recording/shared/responsive/breakpoints.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/section_card.dart';
import 'package:financial_recording/util/money/money_format.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ReportsController(), tag: 'reports');
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Laporan'),
      ),
      body: SingleChildScrollView(
        child: ContentShell(
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final n in [3, 6, 12])
                        ChoiceChip(
                          label: Text('$n bulan'),
                          selected: c.monthsBack.value == n,
                          onSelected: (_) => c.setMonthsBack(n),
                        ),
                    ],
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
                    child: c.expenseByCategory.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Text('Belum ada pengeluaran pada periode ini.'),
                          )
                        : _CategoryBreakdown(slices: c.expenseByCategory),
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
              )),
        ),
      ),
    );
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
          Text(value.rupiah, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
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
              getTitlesWidget: (v, meta) => Text(v.toInt().compact, style: TextStyle(fontSize: 10, color: colors.textTertiary)),
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
                  child: Text(DateFormat('MMM', 'id_ID').format(points[i].month), style: TextStyle(fontSize: 10, color: colors.textTertiary)),
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
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (maxY - minY).abs() / 4 == 0 ? 1 : (maxY - minY).abs() / 4),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, meta) => Text(v.toInt().compact, style: TextStyle(fontSize: 10, color: colors.textTertiary)),
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
                  child: Text(DateFormat('MMM', 'id_ID').format(points[i].month), style: TextStyle(fontSize: 10, color: colors.textTertiary)),
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
                for (final s in slices.take(8))
                  PieChartSectionData(
                    value: s.amount.toDouble(),
                    color: Color(s.colorValue),
                    title: '',
                    radius: 42,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final s in slices.take(8))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(radius: 5, backgroundColor: Color(s.colorValue)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text('${(total == 0 ? 0 : s.amount / total * 100).toStringAsFixed(0)}%', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                const SizedBox(width: AppSpacing.sm),
                Text(s.amount.rupiah, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}

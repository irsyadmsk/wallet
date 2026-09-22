import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/core.dart';
import 'package:financial_recording/presentation/analytics/controller/analytics_controller.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnalyticsController());
    final double appBarHeight = AppBar().preferredSize.height;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Laporan Keuangan",
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              controller.loadAnalytics();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF334155),
                size: 20,
              ),
            ),
            tooltip: "Segarkan Data",
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Period Selector (Horizontal chips)
                _buildPeriodSelector(controller),
                const SizedBox(height: 20),

                // 2. Financial Overview Card (Income, Expense, Net Cashflow)
                _buildCashflowCard(controller),
                const SizedBox(height: 24),

                // 3. Type Switcher (Pengeluaran vs Pemasukan)
                _buildTypeSwitcher(controller),
                const SizedBox(height: 20),

                // 4. Chart & Category Breakdown
                if (controller.categoryStats.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          "Belum ada data transaksi ${controller.selectedType.value == 'expense' ? 'pengeluaran' : 'pemasukan'}\nuntuk periode ini",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Donut Chart
                  Center(
                    child: _buildDonutChart(controller),
                  ),
                  const SizedBox(height: 24),

                  // Section Title
                  Text(
                    "Rincian Per Kategori (${controller.selectedType.value == 'expense' ? 'Pengeluaran' : 'Pemasukan'})",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Breakdown List
                  ...controller.categoryStats.map((stat) => _buildCategoryRow(stat)),
                ],
              ],
            ),
          );
        }),
    );
  }

  Widget _buildPeriodSelector(AnalyticsController controller) {
    final periods = ["Bulan Ini", "Bulan Lalu", "Tahun Ini", "Semua"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((p) {
          final isSelected = controller.selectedPeriod.value == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(p),
              selected: isSelected,
              onSelected: (_) => controller.changePeriod(p),
              selectedColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCashflowCard(AnalyticsController controller) {
    final isPositive = controller.netCashflow.value >= 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Arus Kas Bersih (Cashflow)", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(
                    "Rp ${NumberFormat.decimalPattern('id').format(controller.netCashflow.value)}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? Colors.green[700] : Colors.red[700],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${controller.savingsRate.value.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Pemasukan", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        Text(
                          "Rp ${NumberFormat.decimalPattern('id').format(controller.totalIncome.value)}",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey.shade200),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Pengeluaran", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        Text(
                          "Rp ${NumberFormat.decimalPattern('id').format(controller.totalExpense.value)}",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSwitcher(AnalyticsController controller) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => controller.changeType("expense"),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: controller.selectedType.value == "expense" ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: controller.selectedType.value == "expense"
                      ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Center(
                  child: Text(
                    "Pengeluaran",
                    style: TextStyle(
                      fontWeight: controller.selectedType.value == "expense" ? FontWeight.bold : FontWeight.normal,
                      color: controller.selectedType.value == "expense" ? Colors.red[700] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => controller.changeType("income"),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: controller.selectedType.value == "income" ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: controller.selectedType.value == "income"
                      ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Center(
                  child: Text(
                    "Pemasukan",
                    style: TextStyle(
                      fontWeight: controller.selectedType.value == "income" ? FontWeight.bold : FontWeight.normal,
                      color: controller.selectedType.value == "income" ? Colors.green[700] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(AnalyticsController controller) {
    final totalAmount = controller.selectedType.value == "expense"
        ? controller.totalExpense.value
        : controller.totalIncome.value;

    return Container(
      width: 200,
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: _DonutChartPainter(
              stats: controller.categoryStats,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Total ${controller.selectedType.value == 'expense' ? 'Keluar' : 'Masuk'}",
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                "Rp ${NumberFormat.compact(locale: 'id').format(totalAmount)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(CategoryStat stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: stat.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stat.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                "${stat.percentage.toStringAsFixed(1)}%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: stat.color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Rp ${NumberFormat.decimalPattern('id').format(stat.totalAmount)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (stat.percentage / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(stat.color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${stat.count} transaksi",
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<CategoryStat> stats;

  _DonutChartPainter({required this.stats});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 24.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.grey.shade100;

    canvas.drawCircle(center, radius, basePaint);

    if (stats.isEmpty) return;

    double startAngle = -pi / 2; // start from top (12 o'clock)
    final totalPercentage = stats.fold<double>(0.0, (sum, item) => sum + item.percentage);

    for (var stat in stats) {
      final sweepAngle = (stat.percentage / (totalPercentage > 0 ? totalPercentage : 100)) * 2 * pi;
      if (sweepAngle <= 0) continue;

      final slicePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = stat.color
        ..strokeCap = StrokeCap.butt;

      // Small gap between slices if multiple categories
      final gap = stats.length > 1 ? 0.04 : 0.0;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gap / 2),
        max(0.0, sweepAngle - gap),
        false,
        slicePaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

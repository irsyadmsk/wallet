import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:financial_recording/models/category_model/category_model.dart';
import 'package:financial_recording/models/transaction_model/transaction_model.dart';

class CategoryStat {
  final String name;
  final int totalAmount;
  final double percentage;
  final int count;
  final Color color;
  final String? iconPath;

  CategoryStat({
    required this.name,
    required this.totalAmount,
    required this.percentage,
    required this.count,
    required this.color,
    this.iconPath,
  });
}

class AnalyticsController extends GetxController {
  final RxString selectedPeriod = "Bulan Ini".obs; // "Bulan Ini", "Bulan Lalu", "Tahun Ini", "Semua"
  final RxString selectedType = "expense".obs; // "expense" or "income"

  final RxInt totalIncome = 0.obs;
  final RxInt totalExpense = 0.obs;
  final RxInt netCashflow = 0.obs;
  final RxDouble savingsRate = 0.0.obs;

  final RxList<CategoryStat> categoryStats = <CategoryStat>[].obs;
  final RxBool isLoading = false.obs;

  final List<Color> _defaultColors = [
    const Color(0xFFE53935),
    const Color(0xFFFB8C00),
    const Color(0xFF43A047),
    const Color(0xFF1E88E5),
    const Color(0xFF8E24AA),
    const Color(0xFF00ACC1),
    const Color(0xFFFFB300),
    const Color(0xFF3949AB),
    const Color(0xFFD81B60),
    const Color(0xFF00897B),
    const Color(0xFF7CB342),
    const Color(0xFF6D4C41),
  ];

  @override
  void onInit() {
    super.onInit();
    loadAnalytics();
  }

  void changePeriod(String period) {
    selectedPeriod.value = period;
    loadAnalytics();
  }

  void changeType(String type) {
    selectedType.value = type;
    loadAnalytics();
  }

  void loadAnalytics() {
    isLoading.value = true;
    try {
      final transactionBox = Hive.box<TransactionModel>('transactions');
      final categoryBox = Hive.box<CategoryModel>('categories');

      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = DateTime.now();

      if (selectedPeriod.value == "Bulan Ini") {
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else if (selectedPeriod.value == "Bulan Lalu") {
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
      } else if (selectedPeriod.value == "Tahun Ini") {
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      } else {
        // "Semua"
        startDate = DateTime(2000, 1, 1);
        endDate = DateTime(2100, 1, 1);
      }

      // Filter transactions within period
      final periodTransactions = transactionBox.values.where((t) {
        return t.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            t.createdAt.isBefore(endDate.add(const Duration(seconds: 1)));
      }).toList();

      int inc = 0;
      int exp = 0;

      for (var t in periodTransactions) {
        if (t.type == "income") {
          inc += t.amount;
        } else if (t.type == "expense") {
          exp += t.amount;
        }
      }

      totalIncome.value = inc;
      totalExpense.value = exp;
      netCashflow.value = inc - exp;

      if (inc > 0) {
        savingsRate.value = ((inc - exp) / inc * 100).clamp(-100.0, 100.0);
      } else {
        savingsRate.value = 0.0;
      }

      // Aggregate by category for selectedType ("expense" or "income")
      final targetTransactions = periodTransactions.where((t) => t.type == selectedType.value).toList();
      final targetTotal = selectedType.value == "expense" ? exp : inc;

      final Map<String, int> categoryAmounts = {};
      final Map<String, int> categoryCounts = {};

      for (var t in targetTransactions) {
        categoryAmounts[t.categoryName] = (categoryAmounts[t.categoryName] ?? 0) + t.amount;
        categoryCounts[t.categoryName] = (categoryCounts[t.categoryName] ?? 0) + 1;
      }

      // Map category metadata (color, icon)
      final Map<String, CategoryModel> categoryMeta = {};
      for (var c in categoryBox.values) {
        categoryMeta[c.name] = c;
      }

      final List<CategoryStat> stats = [];
      int colorIndex = 0;

      // Sort categories by amount descending
      final sortedEntries = categoryAmounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (var entry in sortedEntries) {
        final catName = entry.key;
        final amount = entry.value;
        final count = categoryCounts[catName] ?? 0;
        final pct = targetTotal > 0 ? (amount / targetTotal) * 100 : 0.0;

        Color catColor = _defaultColors[colorIndex % _defaultColors.length];
        String? iconPath;

        if (categoryMeta.containsKey(catName)) {
          final meta = categoryMeta[catName]!;
          iconPath = meta.iconPath;
          if (meta.color != null && meta.color!.isNotEmpty) {
            try {
              catColor = Color(int.parse(meta.color!));
            } catch (_) {}
          }
        }

        stats.add(CategoryStat(
          name: catName,
          totalAmount: amount,
          percentage: pct,
          count: count,
          color: catColor,
          iconPath: iconPath,
        ));
        colorIndex++;
      }

      categoryStats.assignAll(stats);
    } catch (e) {
      debugPrint("Error loading analytics: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

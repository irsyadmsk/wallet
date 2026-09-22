import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/models/transaction_model/transaction_model.dart';
import 'package:financial_recording/util/db_service/db_service.dart';

class BudgetInfo {
  final int limit;
  final int spent;
  final int remaining;
  final double percentage;
  final String statusText;
  final Color statusColor;

  BudgetInfo({
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.statusText,
    required this.statusColor,
  });
}

class BudgetService {
  static const String _keyBudgetLimit = "monthly_budget_limit";
  static const int defaultLimit = 5000000; // Rp 5.000.000

  static int getBudgetLimit() {
    final val = DBService.get(_keyBudgetLimit);
    if (val == null) return defaultLimit;
    return int.tryParse(val.toString()) ?? defaultLimit;
  }

  static Future<void> setBudgetLimit(int newLimit) async {
    await DBService.set(_keyBudgetLimit, newLimit.toString());
  }

  static BudgetInfo calculateCurrentMonthBudget() {
    final limit = getBudgetLimit();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    int spent = 0;
    try {
      final box = Hive.box<TransactionModel>(AppConfig.transactionBoxName);
      for (var t in box.values) {
        if (t.type == 'expense') {
          if (t.createdAt.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
              t.createdAt.isBefore(endOfMonth.add(const Duration(seconds: 1)))) {
            spent += t.amount;
          }
        }
      }
    } catch (_) {}

    final remaining = limit - spent;
    final percentage = limit > 0 ? (spent / limit * 100) : 0.0;

    String statusText;
    Color statusColor;

    if (percentage >= 100) {
      statusText = "Melebihi Anggaran";
      statusColor = const Color(0xFFEF4444); // Red
    } else if (percentage >= 80) {
      statusText = "Waspada (Hampir Penuh)";
      statusColor = const Color(0xFFF59E0B); // Amber
    } else {
      statusText = "Aman";
      statusColor = const Color(0xFF10B981); // Emerald
    }

    return BudgetInfo(
      limit: limit,
      spent: spent,
      remaining: remaining,
      percentage: percentage,
      statusText: statusText,
      statusColor: statusColor,
    );
  }
}

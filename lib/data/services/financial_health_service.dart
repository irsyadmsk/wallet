import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/goal_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_query.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/budget_service_v2.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/util/money/money_format.dart';

enum FinancialHealthGrade {
  excellent, // 80 - 100: Sangat Sehat
  good,      // 60 - 79: Sehat & Terkendali
  fair,      // 40 - 59: Perlu Perhatian
  critical,  // 0 - 39: Waspada Defisit
}

class SmartFinancialInsight {
  final String icon;
  final String title;
  final String message;
  final String type; // 'info', 'success', 'warning', 'alert'

  const SmartFinancialInsight({
    required this.icon,
    required this.title,
    required this.message,
    this.type = 'info',
  });
}

class FinancialHealthReport {
  final int score;
  final FinancialHealthGrade grade;
  final String gradeLabel;
  final double savingsRate;
  final double emergencyRunwayMonths;
  final double budgetDisciplineRate;
  final double debtToAssetRatio;
  final int safeDailySpend;
  final int daysRemainingInMonth;
  final List<SmartFinancialInsight> insights;

  const FinancialHealthReport({
    required this.score,
    required this.grade,
    required this.gradeLabel,
    required this.savingsRate,
    required this.emergencyRunwayMonths,
    required this.budgetDisciplineRate,
    required this.debtToAssetRatio,
    required this.safeDailySpend,
    required this.daysRemainingInMonth,
    required this.insights,
  });
}

class FinancialHealthService {
  final _accounts = AccountRepository();
  final _txs = TxRepository();
  final _budgets = BudgetServiceV2();
  final _categories = TxCategoryRepository();
  final _goals = FinancialGoalRepository();

  FinancialHealthReport calculateReport([DateTime? date]) {
    final now = date ?? DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;
    final daysRemaining = (daysInMonth - now.day + 1).clamp(1, 31);

    // 1. Bulan ini Income & Expense
    final monthTxs = _txs.query(TxQuery(from: firstDay, to: DateTime(now.year, now.month + 1, 1)));
    final monthIncome = monthTxs.where((t) => t.type == TxType.income).fold(0, (s, t) => s + t.amount);
    final monthExpense = monthTxs.where((t) => t.type == TxType.expense).fold(0, (s, t) => s + t.amount);

    // 2. Savings Rate (Rasio Tabungan)
    double savingsRate = 0.0;
    int savingsScore = 0;
    if (monthIncome > 0) {
      savingsRate = (monthIncome - monthExpense) / monthIncome;
      if (savingsRate >= 0.20) {
        savingsScore = 25;
      } else if (savingsRate >= 0.10) {
        savingsScore = 18;
      } else if (savingsRate >= 0.0) {
        savingsScore = 10;
      } else {
        savingsScore = 2; // Defisit
      }
    } else {
      savingsScore = monthExpense == 0 ? 20 : 5;
    }

    // 3. Ketahanan Dana Darurat (Emergency Runway)
    final allAccs = _accounts.all();
    final liquidAssets = allAccs
        .where((a) => !a.isLiability && a.cachedBalance > 0)
        .fold<int>(0, (s, a) => s + a.cachedBalance);

    // Hitung rata-rata pengeluaran 3 bulan terakhir
    final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
    final pastTxs = _txs.query(TxQuery(from: threeMonthsAgo, to: DateTime(now.year, now.month + 1, 1)));
    final pastExpenses = pastTxs.where((t) => t.type == TxType.expense).fold(0, (s, t) => s + t.amount);
    final avgMonthlyExpense = (pastExpenses / 3).round();
    final effectiveExpense = avgMonthlyExpense > 0 ? avgMonthlyExpense : (monthExpense > 0 ? monthExpense : 1);

    final emergencyRunwayMonths = liquidAssets / effectiveExpense;
    int emergencyScore = 0;
    if (emergencyRunwayMonths >= 6.0) {
      emergencyScore = 25;
    } else if (emergencyRunwayMonths >= 3.0) {
      emergencyScore = 20;
    } else if (emergencyRunwayMonths >= 1.0) {
      emergencyScore = 12;
    } else {
      emergencyScore = 5;
    }

    // 4. Disiplin Anggaran (Budget Discipline)
    final catProgress = _budgets.categoryProgress(now);
    double budgetDisciplineRate = 1.0;
    int budgetScore = 20;
    if (catProgress.isNotEmpty) {
      final healthyBudgets = catProgress.where((b) => b.limit > 0 ? b.spent <= b.limit : true).length;
      budgetDisciplineRate = healthyBudgets / catProgress.length;
      if (budgetDisciplineRate >= 1.0) {
        budgetScore = 25;
      } else if (budgetDisciplineRate >= 0.75) {
        budgetScore = 18;
      } else if (budgetDisciplineRate >= 0.50) {
        budgetScore = 10;
      } else {
        budgetScore = 3;
      }
    }

    // 5. Rasio Utang terhadap Aset (Debt-to-Asset)
    final totalAssets = _accounts.totalAssets;
    final totalLiabilities = _accounts.totalLiabilities;
    double debtToAssetRatio = 0.0;
    int debtScore = 25;
    if (totalAssets > 0) {
      debtToAssetRatio = totalLiabilities / totalAssets;
      if (debtToAssetRatio <= 0.05) {
        debtScore = 25;
      } else if (debtToAssetRatio <= 0.30) {
        debtScore = 20;
      } else if (debtToAssetRatio <= 0.60) {
        debtScore = 12;
      } else {
        debtScore = 5;
      }
    } else if (totalLiabilities > 0) {
      debtScore = 0;
      debtToAssetRatio = 1.0;
    }

    // Total Skor
    final totalScore = (savingsScore + emergencyScore + budgetScore + debtScore).clamp(0, 100);

    FinancialHealthGrade grade;
    String gradeLabel;
    if (totalScore >= 80) {
      grade = FinancialHealthGrade.excellent;
      gradeLabel = 'Sangat Sehat 🌿';
    } else if (totalScore >= 60) {
      grade = FinancialHealthGrade.good;
      gradeLabel = 'Sehat & Terkendali ✨';
    } else if (totalScore >= 40) {
      grade = FinancialHealthGrade.fair;
      gradeLabel = 'Perlu Perhatian ⚠️';
    } else {
      grade = FinancialHealthGrade.critical;
      gradeLabel = 'Waspada Defisit 🚨';
    }

    // 6. Safe-to-Spend Daily
    final overallProg = _budgets.overallProgress(now);
    int safeDailySpend = 0;
    if (overallProg.limit > 0) {
      final remainingBudget = (overallProg.limit - overallProg.spent).clamp(0, overallProg.limit);
      safeDailySpend = (remainingBudget / daysRemaining).round();
    } else {
      final surplus = (monthIncome - monthExpense).clamp(0, monthIncome);
      safeDailySpend = (surplus / daysRemaining).round();
    }

    // 7. Dynamic Actionable Insights
    final insights = <SmartFinancialInsight>[];

    // Insight 1: Savings Rate
    if (savingsRate >= 0.20) {
      insights.add(SmartFinancialInsight(
        icon: 'savings',
        title: 'Tabungan Unggul',
        message: 'Luar biasa! Anda menyisihkan ${(savingsRate * 100).toStringAsFixed(1)}% dari pemasukan bulan ini.',
        type: 'success',
      ));
    } else if (monthExpense > monthIncome && monthIncome > 0) {
      insights.add(SmartFinancialInsight(
        icon: 'warning',
        title: 'Arus Kas Defisit',
        message: 'Pengeluaran bulan ini melebihi pemasukan sebesar ${(monthExpense - monthIncome).rupiah}. Kurangi belanja non-esensial.',
        type: 'alert',
      ));
    }

    // Insight 2: Emergency Fund
    if (emergencyRunwayMonths >= 6.0) {
      insights.add(SmartFinancialInsight(
        icon: 'shield',
        title: 'Dana Darurat Sangat Aman',
        message: 'Aset likuid Anda dapat mencukupi hidup selama ${emergencyRunwayMonths.toStringAsFixed(1)} bulan ke depan.',
        type: 'success',
      ));
    } else if (emergencyRunwayMonths < 3.0 && emergencyRunwayMonths > 0) {
      insights.add(SmartFinancialInsight(
        icon: 'shield_moon',
        title: 'Perkuat Dana Darurat',
        message: 'Dana darurat Anda saat ini mencukupi ${emergencyRunwayMonths.toStringAsFixed(1)} bulan. Disarankan memiliki cadangan 3-6 bulan.',
        type: 'warning',
      ));
    }

    // Insight 3: Over-budget categories
    final overBudgets = catProgress.where((b) => b.isOver).toList();
    if (overBudgets.isNotEmpty) {
      final first = overBudgets.first;
      final catName = _categories.byId(first.categoryId ?? '')?.displayName ?? 'Kategori';
      insights.add(SmartFinancialInsight(
        icon: 'trending_up',
        title: 'Anggaran Melewati Batas',
        message: 'Kategori "$catName" melebihi limit sebesar ${(first.spent - first.limit).rupiah}.',
        type: 'alert',
      ));
    }

    // Insight 4: Top expense category
    final expenseTxs = monthTxs.where((t) => t.type == TxType.expense).toList();
    if (expenseTxs.isNotEmpty) {
      final byCat = <String, int>{};
      for (final t in expenseTxs) {
        final catId = t.categoryId ?? 'none';
        byCat[catId] = (byCat[catId] ?? 0) + t.amount;
      }
      final sortedCats = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      if (sortedCats.isNotEmpty) {
        final topCatId = sortedCats.first.key;
        final topAmount = sortedCats.first.value;
        final topCatName = _categories.byId(topCatId)?.displayName ?? 'Lainnya';
        final pct = monthExpense > 0 ? ((topAmount / monthExpense) * 100).round() : 0;
        insights.add(SmartFinancialInsight(
          icon: 'pie_chart',
          title: 'Fokus Belanja Utama',
          message: 'Porsi belanja terbesar bulan ini ada pada "$topCatName" sebesar ${topAmount.rupiah} ($pct% total belanja).',
          type: 'info',
        ));
      }
    }

    // Insight 5: Goals progress
    final activeGoals = _goals.active();
    if (activeGoals.isNotEmpty) {
      final g = activeGoals.first;
      insights.add(SmartFinancialInsight(
        icon: 'flag',
        title: 'Target Tabungan: ${g.title}',
        message: 'Progres mencapai ${g.progressPercent}% (${g.currentAmount.rupiah} dari ${g.targetAmount.rupiah}).',
        type: 'info',
      ));
    }

    return FinancialHealthReport(
      score: totalScore,
      grade: grade,
      gradeLabel: gradeLabel,
      savingsRate: savingsRate,
      emergencyRunwayMonths: emergencyRunwayMonths,
      budgetDisciplineRate: budgetDisciplineRate,
      debtToAssetRatio: debtToAssetRatio,
      safeDailySpend: safeDailySpend,
      daysRemainingInMonth: daysRemaining,
      insights: insights,
    );
  }
}

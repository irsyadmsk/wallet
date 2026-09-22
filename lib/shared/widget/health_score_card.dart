import 'package:flutter/material.dart';
import 'package:financial_recording/data/services/financial_health_service.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/section_card.dart';
import 'package:financial_recording/util/money/money_format.dart';

class HealthScoreCard extends StatefulWidget {
  const HealthScoreCard({super.key, required this.report});

  final FinancialHealthReport report;

  @override
  State<HealthScoreCard> createState() => _HealthScoreCardState();
}

class _HealthScoreCardState extends State<HealthScoreCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final r = widget.report;

    Color scoreColor;
    switch (r.grade) {
      case FinancialHealthGrade.excellent:
        scoreColor = const Color(0xFF0D9488); // Sage Teal
        break;
      case FinancialHealthGrade.good:
        scoreColor = const Color(0xFF2563EB); // Royal Blue
        break;
      case FinancialHealthGrade.fair:
        scoreColor = const Color(0xFFD97706); // Amber
        break;
      case FinancialHealthGrade.critical:
        scoreColor = const Color(0xFFDC2626); // Red
        break;
    }

    return SectionCard(
      title: 'Kesehatan Finansial & Insight',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: scoreColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          r.gradeLabel,
          style: TextStyle(
            color: scoreColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row Score & Safe to Spend
          Row(
            children: [
              // Score Indicator Ring
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withValues(alpha: 0.08),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.35), width: 3),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${r.score}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                        height: 1,
                      ),
                    ),
                    Text(
                      '/ 100',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Safe-to-Spend Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: colors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Batas Belanja Aman Harian',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${r.safeDailySpend.rupiah} / hari',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Sisa ${r.daysRemainingInMonth} hari bulan ini',
                        style: TextStyle(color: colors.textTertiary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 4 Metric Badges
          Row(
            children: [
              _MetricPill(
                label: 'Tabungan',
                value: '${(r.savingsRate * 100).round()}%',
                icon: Icons.savings_outlined,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              _MetricPill(
                label: 'Darurat',
                value: '${r.emergencyRunwayMonths.toStringAsFixed(1)} bln',
                icon: Icons.safety_check_outlined,
                color: colors.income,
              ),
              const SizedBox(width: 6),
              _MetricPill(
                label: 'Disiplin',
                value: '${(r.budgetDisciplineRate * 100).round()}%',
                icon: Icons.fact_check_outlined,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              _MetricPill(
                label: 'Utang/Aset',
                value: '${(r.debtToAssetRatio * 100).round()}%',
                icon: Icons.balance_outlined,
                color: r.debtToAssetRatio > 0.4 ? colors.expense : colors.textSecondary,
              ),
            ],
          ),

          if (r.insights.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < (_expanded ? r.insights.length : 1); i++)
              _InsightItem(insight: r.insights[i]),
            if (r.insights.length > 1)
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _expanded ? 'Tampilkan lebih sedikit' : 'Lihat ${r.insights.length - 1} saran lainnya',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: colors.surfaceAlt.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  const _InsightItem({required this.insight});
  final SmartFinancialInsight insight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    IconData iconData;
    Color iconColor;
    switch (insight.type) {
      case 'success':
        iconData = Icons.check_circle_outline_rounded;
        iconColor = colors.income;
        break;
      case 'alert':
        iconData = Icons.error_outline_rounded;
        iconColor = colors.expense;
        break;
      case 'warning':
        iconData = Icons.warning_amber_rounded;
        iconColor = colors.warning;
        break;
      default:
        iconData = Icons.lightbulb_outline_rounded;
        iconColor = colors.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, size: 18, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  insight.message,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/data/models/template_model/template_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/util/money/money_format.dart';

/// Horizontal 1-tap transaction logger bar.
class QuickTemplateBar extends StatelessWidget {
  const QuickTemplateBar({
    super.key,
    required this.templates,
    required this.onRecorded,
  });

  final List<QuickTemplateModel> templates;
  final VoidCallback onRecorded;

  static const _iconMap = <String, IconData>{
    'coffee': Icons.coffee_rounded,
    'restaurant': Icons.restaurant_rounded,
    'fastfood': Icons.fastfood_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'local_parking': Icons.local_parking_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'receipt': Icons.receipt_long_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (templates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_rounded, size: 18, color: colors.primary),
                const SizedBox(width: 4),
                Text(
                  'Catat Cepat 1-Tap',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              'Tap untuk catat instan',
              style: TextStyle(fontSize: 11, color: colors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final t = templates[index];
              final icon = _iconMap[t.iconName] ?? Icons.receipt_long_rounded;
              final tColor = Color(t.colorValue);

              return InkWell(
                onTap: () => _executeQuickLog(context, t),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: tColor.withValues(alpha: 0.35), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: tColor.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: tColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 14, color: tColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t.amount.rupiah,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _executeQuickLog(BuildContext context, QuickTemplateModel t) async {
    final accounts = AccountRepository().all();
    if (accounts.isEmpty) {
      Get.snackbar('Perhatian', 'Buat akun terlebih dahulu untuk mencatat transaksi.');
      return;
    }

    final accountId = t.accountId != null && AccountRepository().byId(t.accountId!) != null
        ? t.accountId!
        : accounts.first.id;

    final account = AccountRepository().byId(accountId);

    if (t.type == TxType.income) {
      await LedgerService().addIncome(
        accountId: accountId,
        categoryId: t.categoryId ?? 'none',
        amount: t.amount,
        date: DateTime.now(),
        memo: 'Catat Cepat: ${t.name}',
      );
    } else {
      await LedgerService().addExpense(
        accountId: accountId,
        categoryId: t.categoryId ?? 'none',
        amount: t.amount,
        date: DateTime.now(),
        memo: 'Catat Cepat: ${t.name}',
      );
    }

    onRecorded();

    Get.showSnackbar(
      GetSnackBar(
        message: '⚡ Tercatat: ${t.name} (${t.amount.rupiah}) ke ${account?.name ?? 'Akun'}',
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        backgroundColor: const Color(0xFF0D9488),
      ),
    );
  }
}

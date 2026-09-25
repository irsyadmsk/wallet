import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/art_icon.dart';
import 'package:financial_recording/shared/widget/receipt_preview_dialog.dart';
import 'package:financial_recording/data/services/receipt_service.dart';
import 'package:financial_recording/data/services/current_actor.dart';
import 'package:financial_recording/util/money/money_format.dart';

class TxTile extends StatelessWidget {
  const TxTile({
    super.key,
    required this.tx,
    this.accountRepository,
    this.categoryRepository,
    this.onTap,
    this.showAccount = true,
  });

  final TxModel tx;
  final AccountRepository? accountRepository;
  final TxCategoryRepository? categoryRepository;
  final VoidCallback? onTap;
  final bool showAccount;

  static final _dateFormat = DateFormat('d MMM', 'id_ID');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accounts = accountRepository ?? AccountRepository();
    final categories = categoryRepository ?? TxCategoryRepository();

    final account = accounts.byId(tx.accountId);
    final category = tx.categoryId == null ? null : categories.byId(tx.categoryId!);

    final String title;
    final String subtitle;
    final Color amountColor;
    final String amountText;
    final Color baseColor;

    switch (tx.type) {
      case TxType.income:
        title = category?.displayName ?? 'Pemasukan';
        subtitle = showAccount ? (account?.name ?? '-') : (tx.memo ?? '');
        amountColor = colors.income;
        baseColor = category != null ? Color(category.colorValue) : colors.income;
        amountText = tx.amount.signedRupiah;
        break;
      case TxType.expense:
        title = category?.displayName ?? 'Pengeluaran';
        subtitle = showAccount ? (account?.name ?? '-') : (tx.memo ?? '');
        amountColor = colors.expense;
        baseColor = category != null ? Color(category.colorValue) : colors.expense;
        amountText = (-tx.amount).signedRupiah;
        break;
      case TxType.transfer:
        final to = tx.toAccountId == null ? null : accounts.byId(tx.toAccountId!);
        title = 'Transfer';
        subtitle = '${account?.name ?? '-'} → ${to?.name ?? '-'}';
        amountColor = colors.transfer;
        baseColor = colors.transfer;
        amountText = tx.amount.rupiah;
        break;
    }

    final hasReceipt = ReceiptService.receiptExistsCached(tx.imagePath);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              // Aesthetic Squircle Avatar
              _buildAvatar(context, category, baseColor, amountColor),
              const SizedBox(width: AppSpacing.md),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        if (hasReceipt) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => ReceiptPreviewDialog.show(
                              context,
                              imagePath: tx.imagePath!,
                              title: title,
                              subtitle: '${tx.amount.rupiah} · ${account?.name ?? ''}',
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_long_rounded, size: 12, color: colors.primary),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Struk',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        tx.memo != null && tx.memo!.isNotEmpty && showAccount ? '$subtitle · ${tx.memo}' : subtitle,
                        // Family ledgers: name whoever else recorded it.
                        if (tx.createdBy != null && tx.createdBy != CurrentActor.id && (tx.createdByName?.isNotEmpty ?? false))
                          'oleh ${tx.createdByName}',
                      ].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Amount and Date
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountText,
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateFormat.format(tx.date),
                    style: TextStyle(color: colors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, dynamic category, Color baseColor, Color typeColor) {
    final colors = context.colors;
    final emoji = category?.emoji;
    final iconPath = category?.iconPath;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ArtIcon(
          size: 44,
          backgroundColor: baseColor.withValues(alpha: 0.14),
          borderColor: baseColor.withValues(alpha: 0.25),
          emoji: emoji,
          imagePath: iconPath,
          iconColor: baseColor,
          child: (emoji == null || emoji.isEmpty) && (iconPath == null || iconPath.isEmpty)
              ? _fallbackIcon(typeColor)
              : null,
        ),
        // Mini type badge
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: typeColor,
              shape: BoxShape.circle,
              border: Border.all(color: colors.surface, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(
              tx.isIncome
                  ? Icons.arrow_downward_rounded
                  : tx.isExpense
                      ? Icons.arrow_upward_rounded
                      : Icons.sync_alt_rounded,
              color: Colors.white,
              size: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackIcon(Color color) {
    IconData icon;
    switch (tx.type) {
      case TxType.income:
        icon = Icons.south_west_rounded;
        break;
      case TxType.expense:
        icon = Icons.north_east_rounded;
        break;
      case TxType.transfer:
        icon = Icons.swap_horiz_rounded;
        break;
    }
    return Icon(icon, color: color, size: 20);
  }
}

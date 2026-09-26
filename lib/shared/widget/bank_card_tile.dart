import 'package:flutter/material.dart';
import 'package:financial_recording/data/repositories/account_group_repository.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/util/money/money_format.dart';

/// Modern card widget displaying a bank account or e-wallet in a physical
/// fintech card aesthetic, featuring official bank logos and balances.
class BankCardTile extends StatelessWidget {
  const BankCardTile({
    super.key,
    required this.account,
    this.onTap,
    this.width = 230,
  });

  final AccountModel account;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final baseColor = Color(account.colorValue);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              baseColor,
              Color.lerp(baseColor, Colors.black, 0.35)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AccountGroupRepository().of(account.groupCode).label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (account.iconPath != null && account.iconPath!.isNotEmpty)
                  // Near-opaque badge so the logo reads as part of the card.
                  // A BackdropFilter blur used to sit here; behind 82% white
                  // it was invisible yet cost a blur pass per card per frame.
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.88),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.8),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(account.iconPath!, fit: BoxFit.contain),
                  )
                else
                  const Icon(Icons.credit_card_rounded, color: Colors.white70, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.cachedBalance.money(account.currencyCode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

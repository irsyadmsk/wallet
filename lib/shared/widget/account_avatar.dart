import 'package:flutter/material.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/shared/theme/art_icon_theme.dart';
import 'package:financial_recording/shared/widget/art_icon.dart';

/// Shows the account's bank/e-wallet logo or colored wallet avatar,
/// dynamically adapting to the user's ART+ shape preference.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({
    super.key,
    required this.account,
    this.radius = 20,
    this.shapeOverride,
  });

  final AccountModel account;
  final double radius;
  final ArtShape? shapeOverride;

  @override
  Widget build(BuildContext context) {
    final color = Color(account.colorValue);
    final size = radius * 2;

    if (account.iconPath != null && account.iconPath!.isNotEmpty) {
      // A soft off-white (not pure #fff) plus a gentle shadow so the logo
      // reads as a raised badge rather than a sticker cut out of the card.
      return ArtIcon(
        size: size,
        shapeOverride: shapeOverride,
        backgroundColor: const Color(0xFFF6F7F9),
        borderColor: Colors.black.withValues(alpha: 0.06),
        borderWidth: 0.8,
        imagePath: account.iconPath,
        padding: EdgeInsets.all(radius * 0.34),
        showAura: true,
      );
    }

    return ArtIcon(
      size: size,
      shapeOverride: shapeOverride,
      backgroundColor: color.withValues(alpha: 0.14),
      borderColor: color.withValues(alpha: 0.25),
      icon: Icons.account_balance_wallet_rounded,
      iconColor: color,
      iconSize: radius * 1.0,
      showAura: false,
    );
  }
}

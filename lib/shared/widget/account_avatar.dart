import 'package:flutter/material.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/domain/account_presets.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';
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
      // Bank-logo assets already ship as a finished little card (their own
      // flat-color background baked in, corners barely rounded). Framing
      // that inside another padded, differently-colored badge produced a
      // sticker-on-a-sticker look — instead let the asset fill the shape
      // edge to edge so it reads as one surface, with just a hairline
      // border and soft aura to lift it off the page.
      return ArtIcon(
        size: size,
        shapeOverride: shapeOverride,
        backgroundColor: const Color(0xFFF6F7F9),
        borderColor: Colors.black.withValues(alpha: 0.08),
        borderWidth: 0.8,
        padding: EdgeInsets.zero,
        showAura: true,
        child: SizedBox.expand(
          child: Image.asset(
            account.iconPath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.account_balance_rounded,
              color: color,
              size: radius,
            ),
          ),
        ),
      );
    }

    // Banks and e-wallets without a bundled logo get initials in their own
    // colour, so "JakOne Pay" and "Bank DKI" are told apart at a glance.
    final monogram = _monogramGroups.contains(account.groupCode)
        ? accountMonogram(account.name)
        : '';
    if (monogram.isNotEmpty) {
      return ArtIcon(
        size: size,
        shapeOverride: shapeOverride,
        backgroundColor: color,
        borderColor: color,
        showAura: false,
        padding: EdgeInsets.zero,
        child: Center(
          child: ExcludeSemantics(
            child: Text(
              monogram,
              style: TextStyle(
                color: color.computeLuminance() > 0.5
                    ? const Color(0xFF192E28)
                    : Colors.white,
                fontSize: radius * 0.72,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                height: 1,
              ),
            ),
          ),
        ),
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

final _monogramGroups = {
  AccountGroupType.bank.code,
  AccountGroupType.ewallet.code,
};

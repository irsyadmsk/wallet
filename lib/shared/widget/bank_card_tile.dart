import 'package:flutter/material.dart';
import 'package:financial_recording/data/repositories/account_group_repository.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/services/currency/currency.dart';
import 'package:financial_recording/util/money/money_format.dart';

/// An account drawn as a physical card. Its top strip ([tabHeight] tall) is
/// laid out to stand on its own — logo, name, balance — because in the
/// wallet stack only that strip of the cards behind the front one shows.
class BankCardTile extends StatelessWidget {
  const BankCardTile({
    super.key,
    required this.account,
    this.onTap,
    this.width = 230,
    this.notch,
    this.hideBalance = false,
  });

  final AccountModel account;
  final VoidCallback? onTap;
  final double width;

  /// Size of a rounded cut-out in the bottom-right corner (for a button that
  /// sits in it), or null for a plain card.
  final Size? notch;
  final bool hideBalance;

  static const tabHeight = 44.0;
  static const radius = 22.0;

  String get _balance => hideBalance ? '••••••' : account.cachedBalance.money(account.currencyCode);

  @override
  Widget build(BuildContext context) {
    final base = Color(account.colorValue);
    final dark = Color.lerp(base, Colors.black, 0.38)!;
    const white = Colors.white;
    final muted = white.withValues(alpha: 0.72);
    final foreign = account.currencyCode != Currency.idr;

    final content = Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [base, dark], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(
        children: [
          // A soft sheen so the card reads as a surface, not a flat block.
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: white.withValues(alpha: 0.07)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: tabHeight,
                  child: Row(
                    children: [
                      _Logo(account: account),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: white, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Long foreign balances give way to the name, never overflow.
                      Flexible(
                        child: Text(
                          _balance,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: muted, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(foreign ? 'Saldo · ${account.currencyCode}' : 'Saldo', style: TextStyle(color: muted, fontSize: 12)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _balance,
                    style: const TextStyle(color: white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  // Keep text clear of the corner cut-out.
                  padding: EdgeInsets.only(right: notch == null ? 0 : notch!.width - 8),
                  child: Text(
                    AccountGroupRepository().of(account.groupCode).label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: ClipPath(
        clipper: _CardClipper(notch),
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.account});
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final path = account.iconPath;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(3),
      child: path != null && path.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset(path, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox()),
            )
          : Icon(Icons.account_balance_wallet_rounded, size: 18, color: Color(account.colorValue)),
    );
  }
}

/// Rounded card, optionally minus a rounded pocket in the bottom-right corner.
class _CardClipper extends CustomClipper<Path> {
  const _CardClipper(this.notch);
  final Size? notch;

  @override
  Path getClip(Size size) {
    final card = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(BankCardTile.radius)));
    final n = notch;
    if (n == null) return card;
    final pocket = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - n.width, size.height - n.height, n.width + BankCardTile.radius, n.height + BankCardTile.radius),
        const Radius.circular(BankCardTile.radius),
      ));
    return Path.combine(PathOperation.difference, card, pocket);
  }

  @override
  bool shouldReclip(_CardClipper old) => old.notch != notch;
}

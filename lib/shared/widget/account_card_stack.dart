import 'package:flutter/material.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/widget/bank_card_tile.dart';

/// A swipeable, fanned deck of account cards — the focused card sits large
/// and crisp up front, the rest peek out behind it at a slight scale, lift
/// and rotation, like cards fanned in a physical wallet. Ends with a
/// "+ Tambah Akun" card so adding an account is one tap from the dashboard.
class AccountCardStack extends StatefulWidget {
  const AccountCardStack({
    super.key,
    required this.accounts,
    required this.onTapAccount,
    required this.onAddAccount,
  });

  final List<AccountModel> accounts;
  final ValueChanged<AccountModel> onTapAccount;
  final VoidCallback onAddAccount;

  @override
  State<AccountCardStack> createState() => _AccountCardStackState();
}

class _AccountCardStackState extends State<AccountCardStack> {
  late final PageController _controller;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.74)..addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() => _page = _controller.page ?? 0);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.accounts.length + 1;
    return SizedBox(
      height: 172,
      child: PageView.builder(
        controller: _controller,
        itemCount: itemCount,
        padEnds: false,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final delta = (index - _page).clamp(-3.0, 3.0);
          final depth = delta.abs();
          final scale = 1 - (depth * 0.08).clamp(0.0, 0.24);
          final liftY = depth * 12;
          final rotate = delta * -0.045;
          final opacity = (1 - depth * 0.3).clamp(0.4, 1.0);

          final isAddTile = index == widget.accounts.length;
          final card = isAddTile
              ? _AddAccountCard(onTap: widget.onAddAccount)
              : BankCardTile(
                  account: widget.accounts[index],
                  width: double.infinity,
                  onTap: () => widget.onTapAccount(widget.accounts[index]),
                );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translateByDouble(0.0, liftY, 0.0, 1.0)
                ..scaleByDouble(scale, scale, 1.0, 1.0)
                ..rotateZ(rotate),
              child: Opacity(opacity: opacity, child: card),
            ),
          );
        },
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  const _AddAccountCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceAlt.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border, width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: colors.primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambah Akun',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

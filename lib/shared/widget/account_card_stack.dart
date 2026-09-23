import 'package:flutter/material.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/widget/bank_card_tile.dart';

/// A physical-wallet-style deck: the focused card sits fully up front, the
/// rest peek out narrower and dimmer behind it. Tapping a card behind the
/// front one animates it forward — no swiping required — and tapping the
/// front card opens its detail page.
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
  static const _maxVisibleDepth = 3; // front + up to 3 peeking behind it
  static const _cardHeight = 172.0;
  static const _peekStep = 16.0;
  static const _insetStep = 22.0;

  late List<String> _order; // account ids, front-to-back

  @override
  void initState() {
    super.initState();
    _order = widget.accounts.map((a) => a.id).toList();
  }

  @override
  void didUpdateWidget(covariant AccountCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accounts == widget.accounts) return;
    final currentIds = widget.accounts.map((a) => a.id).toSet();
    _order = [
      for (final id in _order) if (currentIds.contains(id)) id,
      for (final a in widget.accounts) if (!_order.contains(a.id)) a.id,
    ];
  }

  void _handleTap(String id) {
    if (_order.first == id) {
      widget.onTapAccount(widget.accounts.firstWhere((a) => a.id == id));
      return;
    }
    setState(() {
      _order.remove(id);
      _order.insert(0, id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accounts.isEmpty) {
      return _AddAccountCard(onTap: widget.onAddAccount, compact: false);
    }

    final colors = context.colors;
    final extraCount = _order.length - 1 - _maxVisibleDepth;
    final stackHeight = _cardHeight + _peekStep * _maxVisibleDepth;

    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Painted back-to-front so the front card wins hit-testing.
          for (final id in _order.reversed)
            Builder(
              builder: (context) {
                final rank = _order.indexOf(id);
                if (rank > _maxVisibleDepth) return const SizedBox.shrink();
                final account = widget.accounts.firstWhere((a) => a.id == id);
                final depth = rank.clamp(0, _maxVisibleDepth);
                final isLastVisible = rank == _maxVisibleDepth && extraCount > 0;

                return AnimatedPositioned(
                  key: ValueKey(id),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  top: depth * _peekStep,
                  left: depth * _insetStep,
                  right: depth * _insetStep,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    opacity: (1 - depth * 0.16).clamp(0.55, 1.0),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => _handleTap(id),
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            BankCardTile(
                              account: account,
                              width: double.infinity,
                            ),
                            if (isLastVisible)
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.38),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '+$extraCount lainnya',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: colors.surface,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onAddAccount,
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Icon(Icons.add_rounded, color: colors.primary, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  const _AddAccountCard({required this.onTap, this.compact = true});
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 172,
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

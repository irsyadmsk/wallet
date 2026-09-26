import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/widget/bank_card_tile.dart';

/// Account cards filed like a physical wallet: the cards behind show as
/// colored tabs (logo · name · balance) above the front card.
///
/// - tap a tab: that card slides down to the front, the old front slides up
///   into the stack;
/// - swipe the front card left: it follows the finger, then files itself at
///   the back and the next card comes forward; swipe right for the previous;
/// - tap the front card: open the account;
/// - "Tambah" sits in a pocket cut into the front card's corner.
///
/// Every move animates on a slightly springy curve, the way the cards in the
/// reference wallet settle.
class AccountCardStack extends StatefulWidget {
  const AccountCardStack({
    super.key,
    required this.accounts,
    required this.onTapAccount,
    required this.onAddAccount,
    this.hideBalance = false,
  });

  final List<AccountModel> accounts;
  final ValueChanged<AccountModel> onTapAccount;
  final VoidCallback onAddAccount;
  final bool hideBalance;

  @override
  State<AccountCardStack> createState() => _AccountCardStackState();
}

class _AccountCardStackState extends State<AccountCardStack> with TickerProviderStateMixin {
  static const _cardHeight = 196.0;
  static const _tab = BankCardTile.tabHeight;
  static const _maxTabs = 4;
  static const _pocket = Size(118, 48);
  static const _move = Duration(milliseconds: 520);
  static const _curve = Curves.easeOutBack;
  static const _spring = SpringDescription(mass: 1, stiffness: 380, damping: 32);

  /// Account ids, front card first.
  List<String> _order = [];

  /// Horizontal offset of the front card while dragged / springing back.
  late final AnimationController _dx = AnimationController.unbounded(vsync: this);

  /// The card just filed away keeps sliding from where the finger left it
  /// to its place in the stack, instead of jumping back to centre first.
  late final AnimationController _backDx = AnimationController.unbounded(vsync: this);
  String? _backId;
  double _width = 1;

  @override
  void initState() {
    super.initState();
    _order = [for (final a in widget.accounts) a.id];
  }

  @override
  void didUpdateWidget(AccountCardStack old) {
    super.didUpdateWidget(old);
    // Keep the user's arrangement; new accounts come in at the front.
    final ids = {for (final a in widget.accounts) a.id};
    final kept = _order.where(ids.contains).toList();
    final added = [for (final a in widget.accounts) if (!kept.contains(a.id)) a.id];
    _order = [...added, ...kept];
  }

  @override
  void dispose() {
    _dx.dispose();
    _backDx.dispose();
    super.dispose();
  }

  AccountModel? _byId(String id) {
    for (final a in widget.accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  void _bringToFront(String id) {
    if (_order.first == id) return;
    HapticFeedback.selectionClick();
    setState(() => _order = [id, ..._order.where((x) => x != id)]);
  }

  void _cycle({required bool forward}) {
    if (_order.length < 2) return;
    HapticFeedback.selectionClick();
    setState(() {
      _order = forward ? [..._order.skip(1), _order.first] : [_order.last, ..._order.take(_order.length - 1)];
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _dx.stop();
    final delta = d.primaryDelta ?? 0;
    // With a single card there's nowhere to go: resist.
    _dx.value += _order.length < 2 ? delta * 0.25 : delta;
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final far = _dx.value.abs() > _width * 0.28;
    final flick = v.abs() > 700;
    if (_order.length > 1 && (far || flick)) {
      final forward = (flick ? v : _dx.value) < 0;
      _backId = _order.first;
      _backDx
        ..value = _dx.value
        ..animateWith(SpringSimulation(_spring, _dx.value, 0, v));
      _dx.value = 0; // the new front comes straight down from its tab
      _cycle(forward: forward);
      return;
    }
    // Not far enough: spring back.
    _dx.animateWith(SpringSimulation(_spring, _dx.value, 0, v));
  }

  double _topFor(int rank, int shown) {
    final r = rank.clamp(0, shown - 1);
    return (shown - 1 - r) * _tab;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (widget.accounts.isEmpty) return _EmptyWallet(onAdd: widget.onAddAccount);

    final shown = math.min(_order.length, _maxTabs + 1);
    final height = (shown - 1) * _tab + _cardHeight;

    return LayoutBuilder(builder: (context, box) {
      _width = math.max(box.maxWidth, 1);
      // Deepest first so the front card paints last.
      final paintOrder = [for (var r = _order.length - 1; r >= 0; r--) r];
      return SizedBox(
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final rank in paintOrder)
              if (_byId(_order[rank]) case final account?)
                AnimatedPositioned(
                  key: ValueKey(account.id),
                  duration: _move,
                  curve: _curve,
                  left: 0,
                  right: 0,
                  top: _topFor(rank, shown),
                  height: _cardHeight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 260),
                    // Beyond the visible tabs the card waits hidden behind.
                    opacity: rank < shown ? 1 : 0,
                    child: rank == 0
                        ? _front(account)
                        : GestureDetector(
                            onTap: () => _bringToFront(account.id),
                            child: AbsorbPointer(
                              child: account.id == _backId
                                  ? AnimatedBuilder(
                                      animation: _backDx,
                                      builder: (context, child) => Transform.translate(offset: Offset(_backDx.value, 0), child: child),
                                      child: _cardFor(account, front: false),
                                    )
                                  : _cardFor(account, front: false),
                            ),
                          ),
                  ),
                ),
            // The pocket button rides with the front card's position.
            Positioned(
              right: 0,
              bottom: 0,
              width: _pocket.width - 6,
              height: _pocket.height - 6,
              child: _AddPill(onTap: widget.onAddAccount, colors: colors),
            ),
          ],
        ),
      );
    });
  }

  Widget _cardFor(AccountModel a, {required bool front}) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BankCardTile.radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: front ? 0.18 : 0.10),
              blurRadius: front ? 18 : 8,
              offset: Offset(0, front ? 8 : -2),
            ),
          ],
        ),
        child: BankCardTile(
          account: a,
          width: double.infinity,
          notch: front ? _pocket : null,
          hideBalance: widget.hideBalance,
          onTap: front ? () => widget.onTapAccount(a) : null,
        ),
      );

  Widget _front(AccountModel a) => GestureDetector(
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: AnimatedBuilder(
          animation: _dx,
          builder: (context, child) {
            final t = (_dx.value / _width).clamp(-1.0, 1.0);
            return Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..translateByDouble(_dx.value, 0.0, 0.0, 1.0)
                ..rotateZ(t * 0.10),
              child: child,
            );
          },
          child: _cardFor(a, front: true),
        ),
      );
}

class _AddPill extends StatelessWidget {
  const _AddPill({required this.onTap, required this.colors});
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Material(
        color: colors.textPrimary,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_rounded, size: 18, color: colors.surface),
              const SizedBox(width: 6),
              Text('Tambah', style: TextStyle(color: colors.surface, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      );
}

class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(BankCardTile.radius),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(BankCardTile.radius),
          border: Border.all(color: colors.border, width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_card_rounded, color: colors.primary, size: 28),
            const SizedBox(height: 8),
            Text('Tambah rekening pertama', style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

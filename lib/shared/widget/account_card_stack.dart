import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/widget/bank_card_tile.dart';

/// A deck of account cards stacked front to back, like cards in a wallet:
/// the front card is full size and the next ones peek out above it, a little
/// smaller each. Drag the front card sideways and it follows the finger; let
/// go and it springs away (the next card rises into place) or back.
/// Ends with a "+ Tambah Akun" card.
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

class _AccountCardStackState extends State<AccountCardStack> with SingleTickerProviderStateMixin {
  /// Position in the deck: 0 = first card in front, 1.5 = halfway through
  /// swapping the second card for the third. Unbounded so a spring can
  /// overshoot slightly.
  late final AnimationController _page = AnimationController.unbounded(vsync: this);

  static const _cardHeight = 150.0;
  static const _peek = 16.0; // how far each card behind shows above
  static const _visibleBehind = 3;
  static const _spring = SpringDescription(mass: 1, stiffness: 320, damping: 30);

  int get _count => widget.accounts.length + 1;
  double _width = 1;
  int _settled = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AccountCardStack old) {
    super.didUpdateWidget(old);
    if (_page.value > _count - 1) _page.value = (_count - 1).toDouble();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _page.stop();
    var next = _page.value - (d.primaryDelta ?? 0) / _width;
    // Rubber-band past either end.
    final max = (_count - 1).toDouble();
    if (next < 0) next = _page.value - (d.primaryDelta ?? 0) / _width * 0.3;
    if (next > max) next = _page.value - (d.primaryDelta ?? 0) / _width * 0.3;
    _page.value = next;
  }

  void _onDragEnd(DragEndDetails d) {
    final v = -(d.primaryVelocity ?? 0) / _width; // pages per second
    var target = _page.value.roundToDouble();
    if (v.abs() > 0.6) target = v > 0 ? _page.value.floorToDouble() + 1 : _page.value.ceilToDouble() - 1;
    target = target.clamp(0, (_count - 1).toDouble());
    _settleTo(target, v);
  }

  void _settleTo(double target, [double velocity = 0]) {
    if (target.round() != _settled) {
      _settled = target.round();
      HapticFeedback.selectionClick();
    }
    _page.animateWith(SpringSimulation(_spring, _page.value, target, velocity));
  }

  Widget _card(int i) {
    if (i == widget.accounts.length) return _AddAccountCard(onTap: widget.onAddAccount);
    final a = widget.accounts[i];
    return BankCardTile(account: a, width: double.infinity, onTap: () => widget.onTapAccount(a));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(builder: (context, box) {
      _width = math.max(box.maxWidth, 1);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: AnimatedBuilder(
          animation: _page,
          builder: (context, _) {
            final p = _page.value;
            // Paint back to front: deepest card first, cards leaving last.
            final order = <int>[
              for (var i = _count - 1; i >= 0; i--)
                if (i - p <= _visibleBehind && i - p > -1.2) i,
            ]..sort((a, b) {
                double key(int i) => i - p < 0 ? -10 - (i - p) : i - p;
                return key(b).compareTo(key(a));
              });
            final front = p.round().clamp(0, _count - 1);
            return Column(
              children: [
                SizedBox(
                  height: _cardHeight + _peek * _visibleBehind,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final i in order) _positioned(i, p, front),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _Dots(count: _count, page: p, color: colors.textPrimary),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _positioned(int i, double p, int front) {
    final d = i - p; // <0: sliding out, 0: front, >0: behind
    double dx = 0, dy = 0, scale = 1, angle = 0, opacity = 1;
    if (d < 0) {
      // The front card follows the finger off to the left with a slight tilt.
      dx = d * _width * 1.05;
      angle = d * 0.12;
      opacity = (1 + d).clamp(0.0, 1.0);
    } else {
      final depth = d.clamp(0.0, _visibleBehind.toDouble());
      dy = -_peek * depth;
      scale = 1 - 0.06 * depth;
      opacity = depth > _visibleBehind - 1 ? (_visibleBehind - depth).clamp(0.0, 1.0) : 1;
    }
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: _cardHeight,
      child: IgnorePointer(
        ignoring: i != front,
        child: Opacity(
          opacity: opacity,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..translateByDouble(dx, dy, 0.0, 1.0)
              ..rotateZ(angle)
              ..scaleByDouble(scale, scale, 1.0, 1.0),
            // Cards behind are dimmed a touch so the front one reads first.
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: (0.1 * d.clamp(0.0, 2.0)).toDouble()),
                BlendMode.srcATop,
              ),
              child: _card(i),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.page, required this.color});
  final int count;
  final double page;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            Builder(builder: (_) {
              final t = (1 - (i - page).abs()).clamp(0.0, 1.0);
              return Container(
                width: 6 + 10 * t,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2 + 0.6 * t),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
        ],
      );
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
          color: colors.surfaceRaised,
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

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';

/// A tile you can nudge around: it follows the finger with a tilt that
/// scales with drag velocity, then springs back home carrying the release
/// velocity — the "cards have inertia" bento interaction. Taps still pass
/// through to [child].
class InertiaTile extends StatefulWidget {
  const InertiaTile({super.key, required this.child, this.maxTilt = 0.08});

  final Widget child;
  final double maxTilt;

  @override
  State<InertiaTile> createState() => _InertiaTileState();
}

class _InertiaTileState extends State<InertiaTile> with TickerProviderStateMixin {
  Offset _offset = Offset.zero;
  double _tilt = 0;
  late final AnimationController _x = AnimationController.unbounded(vsync: this)..addListener(_sync);
  late final AnimationController _y = AnimationController.unbounded(vsync: this)..addListener(_sync);
  late final AnimationController _r = AnimationController.unbounded(vsync: this)..addListener(_sync);
  bool _dragging = false;

  static const _spring = SpringDescription(mass: 1, stiffness: 260, damping: 18);

  void _sync() {
    if (_dragging) return;
    setState(() {
      _offset = Offset(_x.value, _y.value);
      _tilt = _r.value;
    });
  }

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    _r.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    return GestureDetector(
      onPanStart: (_) {
        _dragging = true;
        _x.stop();
        _y.stop();
        _r.stop();
      },
      onPanUpdate: (d) => setState(() {
        // Rubber-band: the further out, the more resistance.
        final resist = 1 / (1 + _offset.distance / 120);
        _offset += d.delta * resist;
        _tilt = (d.delta.dx / 40).clamp(-widget.maxTilt, widget.maxTilt);
      }),
      onPanEnd: (d) {
        _dragging = false;
        final v = d.velocity.pixelsPerSecond;
        _x.value = _offset.dx;
        _y.value = _offset.dy;
        _r.value = _tilt;
        _x.animateWith(SpringSimulation(_spring, _offset.dx, 0, v.dx / 4));
        _y.animateWith(SpringSimulation(_spring, _offset.dy, 0, v.dy / 4));
        _r.animateWith(SpringSimulation(_spring, _tilt, 0, (v.dx / 3000).clamp(-2.0, 2.0)));
      },
      child: Transform.translate(
        offset: _offset,
        child: Transform.rotate(angle: _tilt, child: widget.child),
      ),
    );
  }
}

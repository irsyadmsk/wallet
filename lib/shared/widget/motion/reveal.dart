import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/util/money/money_format.dart';
import 'package:financial_recording/data/services/currency/display_currency.dart';

/// One-shot entrance: fades in while rising [dy] px, delayed by [index]
/// staggers. Starts from an already-visible default when the user prefers
/// reduced motion.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child, this.index = 0, this.dy = 18, this.delay = Duration.zero});

  final Widget child;
  final int index;
  final double dy;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.skipPageMotion(context)) return child;
    final d = delay + AppMotion.stagger * index;
    return child
        .animate(delay: d)
        .fadeIn(duration: AppMotion.reveal, curve: AppMotion.emphasized)
        .moveY(begin: dy, end: 0, duration: AppMotion.reveal, curve: AppMotion.emphasized);
  }
}

/// Splits [text] into words that each rise and fade in with an 80ms stagger —
/// the hero wordmark treatment. [asterisk] adds a small raised "*" after
/// the final word.
class WordsPullUp extends StatelessWidget {
  const WordsPullUp({
    super.key,
    required this.text,
    required this.style,
    this.asterisk = false,
    this.delay = Duration.zero,
    this.textAlign = WrapAlignment.start,
  });

  final String text;
  final TextStyle style;
  final bool asterisk;
  final Duration delay;
  final WrapAlignment textAlign;

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    final reduce = AppMotion.reduced(context);
    final size = style.fontSize ?? 14;
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Wrap(
        alignment: textAlign,
        spacing: size * 0.22,
        children: [
          for (var i = 0; i < words.length; i++)
            _word(words[i], i == words.length - 1 && asterisk, size)
                .animate(delay: delay + const Duration(milliseconds: 80) * i, autoPlay: !reduce)
                .fadeIn(duration: const Duration(milliseconds: 800), curve: AppMotion.emphasized)
                .moveY(begin: size * 0.35, end: 0, duration: const Duration(milliseconds: 800), curve: AppMotion.emphasized),
        ],
      ),
    );
  }

  Widget _word(String w, bool withAsterisk, double size) {
    if (!withAsterisk) return Text(w, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(w, style: style),
        Padding(
          padding: EdgeInsets.only(top: size * 0.12),
          child: Text('*', style: style.copyWith(fontSize: size * 0.31, height: 1)),
        ),
      ],
    );
  }
}

/// Tweens between rupiah amounts so balance changes read as motion rather
/// than a jump. Uses tabular figures so digits don't jitter.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({
    super.key,
    required this.value,
    required this.style,
    this.hidden = false,
    this.signed = false,
    this.compact = false,
    this.inDisplayCurrency = false,
  });

  /// [value] is rupiah; show it in the user's chosen [DisplayCurrency].
  final bool inDisplayCurrency;

  final int value;
  final TextStyle style;
  final bool hidden;
  final bool signed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    if (inDisplayCurrency) {
      return ValueListenableBuilder<String>(
        valueListenable: DisplayCurrency.code,
        builder: (context, _, _) {
          if (hidden) return Text('${DisplayCurrency.symbol} ••••••', style: s);
          return TweenAnimationBuilder<double>(
            tween: Tween(end: value.toDouble()),
            duration: AppMotion.of(context, const Duration(milliseconds: 900)),
            curve: AppMotion.emphasized,
            builder: (context, v, _) => Text(DisplayCurrency.format(v.round()),
                style: s, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
          );
        },
      );
    }
    if (hidden) return Text('Rp ••••••', style: s);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: AppMotion.of(context, const Duration(milliseconds: 900)),
      curve: AppMotion.emphasized,
      builder: (context, v, _) {
        final n = v.round();
        final text = compact ? 'Rp ${n.compact}' : (signed ? n.signedRupiah : n.rupiah);
        return Text(text, style: s, maxLines: 1, overflow: TextOverflow.fade, softWrap: false);
      },
    );
  }
}

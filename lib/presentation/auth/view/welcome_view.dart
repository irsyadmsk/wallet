import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/presentation/auth/view/auth_panel.dart';
import 'package:financial_recording/presentation/auth/view/feature_tour.dart';
import 'package:financial_recording/shared/ecosystem.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';
import 'package:financial_recording/app/guest_mode.dart';

const _heroVideo =
    'https://d8j0ntlcm91z4.cloudfront.net/user_38xzZboKViGWJOttwIXH07lWA1P/hf_20260405_170732_8a9ccda6-5cff-4628-b164-059c500a2b41.mp4';

/// Full-bleed cinematic welcome screen shown until the user signs in.
/// Video background (muted, looping, inline) under dark gradients, a black
/// nav capsule hanging from the top edge, the "Wallet*" wordmark bottom-left
/// and a hover-reveal CTA bottom-right.
class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _paused = false;

  void _togglePlayback() {
    final v = _video;
    if (v == null) return;
    setState(() => _paused = !_paused);
    _paused ? v.pause() : v.play();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleDeepLink();
    if (_video == null && !AppMotion.reduced(context)) _initVideo();
  }

  Future<void> _initVideo() async {
    final v = VideoPlayerController.networkUrl(
      Uri.parse(_heroVideo),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _video = v;
    try {
      await v.initialize();
      await v.setVolume(0);
      await v.setLooping(true);
      await v.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      // Offline or blocked: the painted backdrop stays.
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  void _openAuth(AuthMode mode) => showAuthPanel(context, mode: mode);

  bool _deepLinkHandled = false;

  /// wallet.irsyads.com/masuk and /daftar open the form straight away, so
  /// irsyads.com (and anyone else) can link to "log in to Wallet" directly.
  /// The Worker serves index.html for every path, so these URLs load the app.
  void _handleDeepLink() {
    if (_deepLinkHandled || !kIsWeb) return;
    _deepLinkHandled = true;
    var path = Uri.base.path.toLowerCase();
    if (path.length > 1 && path.endsWith('/')) path = path.substring(0, path.length - 1);
    final AuthMode? mode = switch (path) {
      '/masuk' || '/login' => AuthMode.signIn,
      '/daftar' || '/register' || '/signup' => AuthMode.signUp,
      _ => null,
    };
    if (mode != null) WidgetsBinding.instance.addPostFrameCallback((_) => _openAuth(mode));
  }

  void _openTour(int topic) => showFeatureTour(context, initialTopic: topic, onStart: GuestMode.start);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop: painted aurora first, video fades in over it.
          const _AuroraBackdrop(),
          if (_video != null)
            AnimatedOpacity(
              opacity: _videoReady ? 1 : 0,
              duration: const Duration(milliseconds: 900),
              child: _videoReady
                  ? ClipRect(
                      child: Transform.scale(
                        scale: 1.01,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _video!.value.size.width,
                            height: _video!.value.size.height,
                            child: VideoPlayer(_video!),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          // Cinematic treatment: top veil, heavier bottom veil, side falloff.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x59000000), Color(0x0D000000), Color(0xB3000000)],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x33000000), Color(0x00000000), Color(0x1A000000)],
                ),
              ),
            ),
          ),

          // Nav capsule, attached to the top edge.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: _NavCapsule(onTopic: _openTour, onSignIn: () => _openAuth(AuthMode.signIn))),
          ),

          // Wordmark + CTA block.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 48 : (size.width >= 640 ? 32 : 16),
                  0,
                  wide ? 48 : (size.width >= 640 ? 32 : 16),
                  wide ? 28 : 20,
                ),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(flex: 8, child: _Wordmark(width: size.width)),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _CtaGroup(onPressed: GuestMode.start, onSignIn: () => _openAuth(AuthMode.signIn)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Wordmark(width: size.width),
                          const SizedBox(height: 20),
                          _CtaGroup(onPressed: GuestMode.start, onSignIn: () => _openAuth(AuthMode.signIn)),
                        ],
                      ),
              ),
            ),
          ),

          // Looping background motion must be pausable (WCAG 2.2.2).
          if (_videoReady)
            Positioned(
              right: 16,
              top: MediaQuery.paddingOf(context).top + 68, // below the nav capsule
              child: Pressable(
                onTap: _togglePlayback,
                semanticLabel: _paused ? 'Putar video latar' : 'Jeda video latar',
                tooltip: _paused ? 'Putar video latar' : 'Jeda video latar',
                hoverLift: 0,
                borderRadius: BorderRadius.circular(99),
                builder: (context, s, _) => AnimatedContainer(
                  duration: AppMotion.hover,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: s.active ? 0.7 : 0.4),
                  ),
                  child: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18, color: AppColors.cream),
                ),
                child: const SizedBox.shrink(),
              ),
            ),

          // Hairline finish along the bottom edge.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(child: SizedBox(height: 1, child: ColoredBox(color: Color(0x40FFFFFF)))),
          ),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    // "Wallet" is short, so it can run larger than a longer wordmark would.
    final fontSize = width >= 1024 ? math.min(width * 0.2, 380.0) : math.min(width * 0.29, 240.0);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomLeft,
      child: Semantics(
        header: true,
        child: WordsPullUp(
          text: AppConfig.appName,
          asterisk: true,
          style: GoogleFonts.interTight(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            height: 0.8,
            letterSpacing: -fontSize * 0.04,
            color: AppColors.cream,
          ),
        ),
      ),
    );
  }
}

/// Paragraph + CTA treated as one hover group: dark at rest, flipping to
/// white together on hover. Touch devices (no mouse) get the readable white
/// state permanently.
class _CtaGroup extends StatefulWidget {
  const _CtaGroup({required this.onPressed, required this.onSignIn});
  final VoidCallback onPressed;
  final VoidCallback onSignIn;

  @override
  State<_CtaGroup> createState() => _CtaGroupState();
}

class _CtaGroupState extends State<_CtaGroup> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final hasMouse = RendererBinding.instance.mouseTracker.mouseIsConnected;
    final lit = _hover || _focus || !hasMouse;
    const d = Duration(milliseconds: 500);
    const curve = AppMotion.emphasized;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: AnimatedDefaultTextStyle(
              duration: d,
              curve: curve,
              style: GoogleFonts.dmSans(
                fontSize: 15.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: lit ? Colors.white : Colors.black,
              ),
              child: const Text(
                'Catat pemasukan, belanja, dan tabungan seluruh keluarga dalam satu buku kas. '
                'Tersinkron di setiap perangkat, dengan laporan yang menjelaskan ke mana uang Anda pergi.',
              ),
            ),
          ).animate().fadeIn(delay: 450.ms, duration: 850.ms, curve: curve).moveY(begin: 24, end: 0, delay: 450.ms, duration: 850.ms, curve: curve),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Focus(
                onFocusChange: (f) => setState(() => _focus = f),
                child: Pressable(
                  onTap: widget.onPressed,
                  semanticLabel: 'Mulai sekarang tanpa akun',
                  hoverLift: 0,
                  borderRadius: BorderRadius.circular(999),
                  builder: (context, s, _) => AnimatedContainer(
                    duration: d,
                    curve: curve,
                    padding: const EdgeInsets.fromLTRB(22, 5, 5, 5),
                    decoration: BoxDecoration(
                      color: lit ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 40, offset: Offset(0, 12))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: d,
                          curve: curve,
                          style: GoogleFonts.dmSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: lit ? Colors.black : Colors.white,
                          ),
                          child: const Text('Mulai sekarang'),
                        ),
                        AnimatedContainer(duration: d, curve: curve, width: lit && hasMouse ? 24 : 16),
                        AnimatedContainer(
                          duration: d,
                          curve: curve,
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: lit ? Colors.black : Colors.white),
                          child: AnimatedRotation(
                            turns: lit && hasMouse ? -33 / 360 : 0,
                            duration: d,
                            curve: curve,
                            child: Icon(Icons.arrow_forward_rounded, size: 18, color: lit ? Colors.white : Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
              _GhostLink(label: 'Masuk / daftar akun', onTap: widget.onSignIn, lit: lit),
              _GhostLink(label: 'irsyads.com', icon: Icons.north_east_rounded, onTap: Ecosystem.openHome, lit: false),
            ],
          ).animate().fadeIn(delay: 560.ms, duration: 850.ms, curve: curve).moveY(begin: 24, end: 0, delay: 560.ms, duration: 850.ms, curve: curve),
        ],
      ),
    );
  }
}

class _GhostLink extends StatelessWidget {
  const _GhostLink({required this.label, required this.onTap, required this.lit, this.icon});
  final String label;
  final VoidCallback onTap;
  final bool lit;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      hoverLift: 0,
      borderRadius: BorderRadius.circular(8),
      builder: (context, s, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: AnimatedDefaultTextStyle(
          duration: AppMotion.hover,
          style: GoogleFonts.dmSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: s.hovered || lit ? 0.95 : 0.7),
            decoration: s.hovered ? TextDecoration.underline : TextDecoration.none,
            decorationColor: Colors.white70,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 14, color: Colors.white.withValues(alpha: s.hovered || lit ? 0.95 : 0.7)),
              ],
            ],
          ),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

class _NavCapsule extends StatelessWidget {
  const _NavCapsule({required this.onTopic, required this.onSignIn});
  final ValueChanged<int> onTopic;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final items = <(String, VoidCallback)>[
      ('Fitur', () => onTopic(0)),
      ('Keluarga', () => onTopic(1)),
      ('Laporan', () => onTopic(2)),
      ('Keamanan', () => onTopic(3)),
      ('Masuk', onSignIn),
    ];
    final w = MediaQuery.sizeOf(context).width;
    final gap = w >= 1024 ? 44.0 : (w >= 640 ? 28.0 : 16.0);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: w - 16),
      child: Semantics(
        container: true,
        label: 'Navigasi utama',
        child: Container(
          padding: EdgeInsets.fromLTRB(gap * 0.8, MediaQuery.paddingOf(context).top + 10, gap * 0.8, 12),
          decoration: const BoxDecoration(
            color: Color(0xF2000000),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    _NavLink(label: items[i].$1, onTap: items[i].$2),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, curve: AppMotion.emphasized).moveY(begin: -12, end: 0, duration: 600.ms, curve: AppMotion.emphasized);
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final fs = w >= 1024 ? 14.0 : (w >= 640 ? 13.0 : 12.5);
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      hoverLift: 0,
      pressedScale: 0.95,
      borderRadius: BorderRadius.circular(6),
      builder: (context, s, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.dmSans(
                fontSize: fs,
                fontWeight: FontWeight.w500,
                color: AppColors.cream.withValues(alpha: s.active ? 1 : 0.75),
              ),
              child: Text(label),
            ),
            const SizedBox(height: 3),
            // Underline that grows left → right on hover.
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: AppMotion.standard,
              height: 1,
              width: s.active ? fs * label.length * 0.52 : 0,
              color: AppColors.cream,
            ),
          ],
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

/// Slow-drifting dark aurora painted behind the video — also the whole
/// backdrop when the video can't load or motion is reduced.
class _AuroraBackdrop extends StatefulWidget {
  const _AuroraBackdrop();

  @override
  State<_AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<_AuroraBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 24));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _AuroraPainter(_c.value)),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0B1311));
    final a = t * 2 * math.pi;
    void blob(Alignment center, double radius, Color color) {
      final rect = Offset.zero & size;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: center,
            radius: radius,
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }

    blob(Alignment(-0.6 + 0.25 * math.sin(a), -0.3 + 0.2 * math.cos(a)), 0.9, const Color(0xFF2B5A4B).withValues(alpha: 0.55));
    blob(Alignment(0.7 + 0.2 * math.cos(a * 0.8), 0.2 + 0.25 * math.sin(a * 0.8)), 0.8, const Color(0xFF4A5E78).withValues(alpha: 0.4));
    blob(Alignment(0.1 + 0.3 * math.sin(a * 0.6), 0.9), 0.7, const Color(0xFF7A5238).withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.t != t;
}

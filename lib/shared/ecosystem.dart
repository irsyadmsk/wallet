import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:financial_recording/shared/responsive/breakpoints.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';

/// One space in the irsyads.com family.
class EcosystemSpace {
  const EcosystemSpace({
    required this.id,
    required this.label,
    required this.description,
    required this.url,
    required this.letter,
    required this.markColor,
    required this.markInk,
  });

  final String id;
  final String label;
  final String description;
  final Uri url;
  final String letter;
  final Color markColor;
  final Color markInk;
}

/// Wallet is one of the irsyads.com spaces. This mirrors the "Ruang Irsyads"
/// switcher on the main site (`packages/design-tokens/src/Experience.astro`
/// in the irsyads repo): same entries, order, letters and colours, so moving
/// between the spaces feels like one product. Change both together.
abstract class Ecosystem {
  static const currentId = 'wallet';
  static final Uri home = Uri.parse('https://irsyads.com');

  static final List<EcosystemSpace> spaces = [
    EcosystemSpace(
      id: 'site',
      label: 'Situs utama',
      description: 'Karya, gagasan, dan perjumpaan',
      url: Uri.parse('https://irsyads.com/'),
      letter: 'i',
      markColor: const Color(0xFF66D6BF),
      markInk: const Color(0xFF1A1512),
    ),
    EcosystemSpace(
      id: 'academy',
      label: 'Academy',
      description: 'Kelas dan perjalanan belajar',
      url: Uri.parse('https://academy.irsyads.com/'),
      letter: 'a',
      markColor: const Color(0xFFF6C76B),
      markInk: const Color(0xFF1A1512),
    ),
    EcosystemSpace(
      id: 'studio',
      label: 'Studio',
      description: 'Kelola situs dan pembelajaran',
      url: Uri.parse('https://irsyads.com/studio'),
      letter: 's',
      markColor: const Color(0xFFB7A4E5),
      markInk: const Color(0xFF1A1512),
    ),
    EcosystemSpace(
      id: 'ruang',
      label: 'Ruang',
      description: 'Alat keluarga, kalkulator & modul ajar',
      url: Uri.parse('https://app.irsyads.com/'),
      letter: 'r',
      markColor: const Color(0xFF192A40),
      markInk: const Color(0xFFF7F8FA),
    ),
    EcosystemSpace(
      id: 'wallet',
      label: 'Wallet',
      description: 'Buku kas pribadi & keluarga',
      url: Uri.parse('https://wallet.irsyads.com/'),
      letter: 'w',
      markColor: const Color(0xFF19363B),
      markInk: const Color(0xFFE1E0CC),
    ),
  ];

  /// Opens irsyads.com in a new tab (web) or the external browser (mobile).
  static Future<void> openHome() => open(home);

  static Future<void> open(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');

  /// The switcher: a bottom sheet on phones, a floating panel beside the
  /// sidebar on wider screens.
  static Future<void> showSwitcher(BuildContext context) {
    if (context.isCompact) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const SafeArea(
          child: Padding(padding: EdgeInsets.fromLTRB(12, 0, 12, 12), child: EcosystemPanel()),
        ),
      );
    }
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup Ruang Irsyads',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => const SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 104, 16, 16),
            child: Material(
              type: MaterialType.transparency,
              child: SizedBox(width: 340, child: _FloatingCard(child: EcosystemPanel())),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -0.02), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: const [BoxShadow(color: Color(0x26102337), blurRadius: 70, offset: Offset(0, 20))],
      ),
      child: child,
    );
  }
}

/// The list of spaces, shared by the sheet and the floating panel.
class EcosystemPanel extends StatelessWidget {
  const EcosystemPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
          child: Text(
            'RUANG IRSYADS · PILIH RUANG ANDA',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: c.textTertiary),
          ),
        ),
        for (final space in Ecosystem.spaces) _SpaceRow(space: space),
      ],
    );
  }
}

class _SpaceRow extends StatelessWidget {
  const _SpaceRow({required this.space});
  final EcosystemSpace space;

  bool get _current => space.id == Ecosystem.currentId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: () {
        Navigator.of(context).maybePop();
        if (!_current) Ecosystem.open(space.url);
      },
      semanticLabel: _current ? '${space.label}, ruang yang sedang dibuka' : 'Buka ${space.label}',
      hoverLift: 0,
      borderRadius: BorderRadius.circular(12),
      builder: (context, s, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _current || s.hovered ? c.surfaceAlt : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: space.markColor, borderRadius: BorderRadius.circular(12)),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: space.letter, style: AppTypography.serif(size: 27, color: space.markInk, italic: false)),
                  TextSpan(text: '·', style: TextStyle(fontSize: 16, color: space.markInk)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(space.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.textPrimary)),
                  const SizedBox(height: 3),
                  Text(space.description, style: TextStyle(fontSize: 11.5, height: 1.4, color: c.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _current
                ? Container(width: 7, height: 7, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle))
                : Icon(Icons.north_east_rounded, size: 16, color: s.hovered ? c.textPrimary : c.textTertiary),
          ],
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

/// Sidebar trigger: a quiet pill, like the "Ruang Irsyads" button on the
/// main site's header.
class EcosystemPill extends StatelessWidget {
  const EcosystemPill({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Pressable(
        onTap: () => Ecosystem.showSwitcher(context),
        semanticLabel: 'Ruang Irsyads: pindah ke irsyads.com, Academy, Studio, atau Ruang',
        tooltip: 'Pindah ke ruang lain di irsyads.com',
        hoverLift: 0,
        borderRadius: BorderRadius.circular(999),
        builder: (context, s, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: s.hovered ? c.surfaceAlt : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grid_view_rounded, size: 15, color: c.textSecondary),
              const SizedBox(width: 7),
              Text('Ruang Irsyads', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textPrimary)),
              const SizedBox(width: 4),
              Icon(Icons.expand_more_rounded, size: 16, color: c.textTertiary),
            ],
          ),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

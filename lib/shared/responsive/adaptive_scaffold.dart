import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/app/sync_controller.dart';
import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/presentation/auth/controller/auth_controller.dart';
import 'package:financial_recording/shared/ecosystem.dart';
import 'package:financial_recording/shared/responsive/breakpoints.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/shared/theme/theme_controller.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';

enum NavGroup {
  main('Utama'),
  plans('Rencana & ibadah'),
  system('Keluarga & pengaturan');

  final String title;
  const NavGroup(this.title);
}

class AdaptiveDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Shorter label for the bottom bar and the "Lainnya" tiles.
  final String? shortLabel;

  /// One line shown under the label on the "Lainnya" tiles.
  final String? hint;
  final bool showInBottomBar;
  final NavGroup group;

  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.shortLabel,
    this.hint,
    this.showInBottomBar = true,
    this.group = NavGroup.main,
  });

  String get bottomBarLabel => shortLabel ?? label;
}

/// Responsive shell:
/// - phone: floating bottom bar (bottom-bar pages + centre "+" + "Lainnya");
/// - tablet: 76px icon rail;
/// - desktop (≥ 1024): 264px sidebar with grouped sections, the primary
///   "Catat transaksi" action, and sync/account status in the footer.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.index,
    required this.onSelect,
    required this.body,
    this.floatingActionButton,
    this.onQuickAction,
    this.appBarTitle,
    this.appBarActions,
  });

  final List<AdaptiveDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;
  final Widget body;
  final Widget? floatingActionButton;
  final VoidCallback? onQuickAction;
  final String? appBarTitle;
  final List<Widget>? appBarActions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final width = MediaQuery.sizeOf(context).width;

    if (context.isCompact) {
      return Scaffold(
        backgroundColor: c.surfaceAlt,
        extendBody: true,
        body: body,
        bottomNavigationBar: _PhoneBar(
          destinations: destinations,
          index: index,
          onSelect: onSelect,
          onQuickAction: onQuickAction,
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.surfaceAlt,
      body: Row(
        children: [
          if (width >= 1024)
            _Sidebar(destinations: destinations, index: index, onSelect: onSelect, onQuickAction: onQuickAction)
          else
            _Rail(destinations: destinations, index: index, onSelect: onSelect, onQuickAction: onQuickAction),
          Expanded(child: ClipRect(child: body)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ phone

class _PhoneBar extends StatelessWidget {
  const _PhoneBar({required this.destinations, required this.index, required this.onSelect, this.onQuickAction});
  final List<AdaptiveDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bar = destinations.where((d) => d.showInBottomBar).toList();
    final half = (bar.length / 2).ceil();
    final inMore = !destinations[index].showInBottomBar;

    Widget item(AdaptiveDestination d) {
      final i = destinations.indexOf(d);
      return Expanded(child: _BarItem(d: d, selected: i == index, onTap: () => onSelect(i)));
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              for (final d in bar.take(half)) item(d),
              if (onQuickAction != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _AddButton(onTap: onQuickAction!),
                ),
              for (final d in bar.skip(half)) item(d),
              Expanded(
                child: _BarItem(
                  d: const AdaptiveDestination(
                    icon: Icons.grid_view_outlined,
                    selectedIcon: Icons.grid_view_rounded,
                    label: 'Lainnya',
                  ),
                  selected: inMore,
                  onTap: () => _showMore(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _MoreSheet(
        destinations: destinations,
        index: index,
        onSelect: (i) {
          Navigator.pop(ctx);
          onSelect(i);
        },
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({required this.d, required this.selected, required this.onTap});
  final AdaptiveDestination d;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticLabel: d.bottomBarLabel,
        hoverLift: 0,
        pressedScale: 0.9,
        borderRadius: BorderRadius.circular(16),
        builder: (context, s, _) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppMotion.base,
              curve: AppMotion.standard,
              width: selected ? 48 : 36,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? c.textPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
              child: AnimatedSwitcher(
                duration: AppMotion.hover,
                child: Icon(
                  selected ? d.selectedIcon : d.icon,
                  key: ValueKey(selected),
                  size: 21,
                  color: selected ? c.surfaceAlt : c.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppMotion.hover,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? c.textPrimary : c.textSecondary,
              ),
              child: Text(d.bottomBarLabel, maxLines: 1, overflow: TextOverflow.clip),
            ),
          ],
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

/// Centre "+" — spins a quarter turn while pressed.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Catat transaksi',
      tooltip: 'Catat transaksi',
      hoverLift: 0,
      pressedScale: 0.88,
      borderRadius: BorderRadius.circular(99),
      builder: (context, s, _) => AnimatedContainer(
        duration: AppMotion.hover,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: s.active ? c.primary : c.textPrimary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: c.textPrimary.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: AnimatedRotation(
          turns: s.pressed ? 0.25 : 0,
          duration: AppMotion.base,
          curve: AppMotion.emphasized,
          child: Icon(Icons.add_rounded, color: c.surfaceAlt, size: 28),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

/// "Lainnya": every page not in the bottom bar as a bento of tiles you can
/// nudge around — they drift back with inertia.
class _MoreSheet extends StatelessWidget {
  const _MoreSheet({required this.destinations, required this.index, required this.onSelect});
  final List<AdaptiveDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final more = [for (var i = 0; i < destinations.length; i++) if (!destinations[i].showInBottomBar) i];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(4))),
          ),
          const SizedBox(height: 16),
          Text('Semua menu', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.92,
            children: [
              for (var k = 0; k < more.length; k++)
                Reveal(
                  index: k,
                  dy: 12,
                  child: InertiaTile(
                    child: _Tile(d: destinations[more[k]], selected: more[k] == index, onTap: () => onSelect(more[k])),
                  ),
                ),
              Reveal(
                index: more.length,
                dy: 12,
                child: InertiaTile(
                  child: _Tile(
                    d: const AdaptiveDestination(
                      icon: Icons.grid_view_rounded,
                      selectedIcon: Icons.grid_view_rounded,
                      label: 'Ruang Irsyads',
                      hint: 'irsyads.com & lainnya',
                    ),
                    selected: false,
                    onTap: () => Ecosystem.showSwitcher(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.d, required this.selected, required this.onTap});
  final AdaptiveDestination d;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: d.label,
      borderRadius: BorderRadius.circular(16),
      builder: (context, s, _) => AnimatedContainer(
        duration: AppMotion.hover,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? c.textPrimary : (s.active ? c.primaryContainer : c.surfaceAlt),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Colors.transparent : c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(selected ? d.selectedIcon : d.icon, color: selected ? c.surfaceAlt : c.textPrimary, size: 24),
            const Spacer(),
            Text(
              d.bottomBarLabel,
              maxLines: 2,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.2, color: selected ? c.surfaceAlt : c.textPrimary),
            ),
            if (d.hint != null)
              Text(
                d.hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: selected ? c.surfaceAlt.withValues(alpha: 0.7) : c.textTertiary),
              ),
          ],
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

// ---------------------------------------------------------------- desktop

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.destinations, required this.index, required this.onSelect, this.onQuickAction});
  final List<AdaptiveDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 264,
      decoration: BoxDecoration(color: c.surface, border: Border(right: BorderSide(color: c.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConfig.appName, style: AppTypography.display(size: 30, weight: FontWeight.w500, color: c.textPrimary)),
                Text('*', style: TextStyle(fontSize: 14, color: c.textPrimary, height: 1)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 2, 20, 16),
            child: EcosystemPill(),
          ),
          if (onQuickAction != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: WButton(label: 'Catat transaksi', icon: Icons.add_rounded, expand: true, onPressed: onQuickAction),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              children: [
                for (final g in NavGroup.values) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
                    child: Text(g.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textTertiary)),
                  ),
                  for (var i = 0; i < destinations.length; i++)
                    if (destinations[i].group == g)
                      _SideItem(d: destinations[i], selected: i == index, onTap: () => onSelect(i)),
                ],
              ],
            ),
          ),
          const _SidebarFooter(),
        ],
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({required this.d, required this.selected, required this.onTap});
  final AdaptiveDestination d;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        selected: selected,
        child: Pressable(
          onTap: onTap,
          semanticLabel: d.label,
          hoverLift: 0,
          pressedScale: 0.98,
          borderRadius: BorderRadius.circular(12),
          builder: (context, s, _) => AnimatedContainer(
            duration: AppMotion.hover,
            curve: AppMotion.standard,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? c.textPrimary : (s.hovered ? c.textPrimary.withValues(alpha: 0.05) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AnimatedSlide(
                  offset: Offset(s.hovered && !selected ? 0.12 : 0, 0),
                  duration: AppMotion.hover,
                  child: Icon(selected ? d.selectedIcon : d.icon, size: 20, color: selected ? c.surfaceAlt : c.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    d.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? c.surfaceAlt : c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = Get.find<AuthController>();
    final sync = Get.find<SyncController>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
      child: Obx(() {
        final name = auth.displayName;
        final family = sync.household.value;
        final ok = sync.errorText.value == null;
        return Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: c.textPrimary,
              child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: TextStyle(color: c.surfaceAlt, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: sync.syncing.value ? c.info : (ok ? c.success : c.warning), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          sync.syncing.value ? 'Menyinkronkan…' : (ok ? (family == null ? 'Tersinkron' : family.name) : 'Offline'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (Get.isRegistered<ThemeController>()) _ThemeToggle(theme: Get.find<ThemeController>()),
          ],
        );
      }),
    );
  }
}

// ----------------------------------------------------------------- tablet

class _Rail extends StatelessWidget {
  const _Rail({required this.destinations, required this.index, required this.onSelect, this.onQuickAction});
  final List<AdaptiveDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 76,
      decoration: BoxDecoration(color: c.surface, border: Border(right: BorderSide(color: c.border))),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: 18),
            Text('W*', style: AppTypography.display(size: 22, weight: FontWeight.w600, color: c.textPrimary)),
            const SizedBox(height: 16),
            if (onQuickAction != null) _AddButton(onTap: onQuickAction!),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Semantics(
                        selected: i == index,
                        child: WIconButton(
                          icon: i == index ? destinations[i].selectedIcon : destinations[i].icon,
                          tooltip: destinations[i].label,
                          size: 48,
                          filled: i == index,
                          color: i == index ? c.primary : c.textSecondary,
                          onPressed: () => onSelect(i),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (Get.isRegistered<ThemeController>()) _ThemeToggle(theme: Get.find<ThemeController>()),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.theme});
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dark = theme.themeMode.value == ThemeMode.dark ||
          (theme.themeMode.value == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
      return WIconButton(
        icon: dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        tooltip: dark ? 'Mode terang' : 'Mode gelap',
        size: 40,
        onPressed: () => theme.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark),
      );
    });
  }
}


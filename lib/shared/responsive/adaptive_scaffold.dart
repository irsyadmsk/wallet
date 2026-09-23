import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/shared/responsive/breakpoints.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/art_icon_theme.dart';
import 'package:financial_recording/shared/theme/theme_controller.dart';
import 'package:financial_recording/shared/widget/art_icon.dart';
import 'package:financial_recording/shared/widget/zen_background.dart';

enum NavGroup {
  main('UTAMA'),
  plans('ASET & RENCANA'),
  system('PENGATURAN');

  final String title;
  const NavGroup(this.title);
}

class AdaptiveDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool showInBottomBar;
  final NavGroup group;

  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.showInBottomBar = true,
    this.group = NavGroup.main,
  });
}

/// Responsive scaffold providing:
/// - Bottom navigation bar on mobile (width < 600)
/// - Compact icon sidebar on tablet (600 <= width < 860)
/// - Modern Desktop Sidebar (260px) on PC/desktop with grouped sections,
///   quick action "+ Catat Transaksi", and live theme switcher.
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
    final isCompact = context.isCompact;
    final colors = context.colors;

    if (isCompact) {
      final bottomBarDestinations = destinations.where((d) => d.showInBottomBar).toList();
      final bottomBarIndex = bottomBarDestinations.indexWhere(
        (d) => destinations.indexOf(d) == index,
      );
      return ZenBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBarTitle == null
              ? null
              : AppBar(
                  backgroundColor: Colors.transparent,
                  title: Text(appBarTitle!),
                  actions: appBarActions,
                ),
          body: body,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.92),
              border: Border(top: BorderSide(color: colors.border.withValues(alpha: 0.6))),
            ),
            // Keeps the bar's icons/labels clear of the home-indicator area
            // on iOS and the gesture bar on Android instead of letting them
            // sit right at (or under) the very edge of the screen.
            child: SafeArea(
              top: false,
              child: NavigationBar(
                selectedIndex: bottomBarIndex < 0 ? 0 : bottomBarIndex,
                onDestinationSelected: (i) => onSelect(destinations.indexOf(bottomBarDestinations[i])),
                destinations: [
                  for (final d in bottomBarDestinations)
                    NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWideDesktop = screenWidth >= 860;

    return ZenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarTitle == null
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                title: Text(appBarTitle!),
                actions: appBarActions,
              ),
        body: Row(
          children: [
            if (isWideDesktop)
              _DesktopSidebar(
                destinations: destinations,
                selectedIndex: index,
                onSelect: onSelect,
                onQuickAction: onQuickAction ?? _extractFabCallback(floatingActionButton),
              )
            else
              _CompactSidebar(
                destinations: destinations,
                selectedIndex: index,
                onSelect: onSelect,
                onQuickAction: onQuickAction ?? _extractFabCallback(floatingActionButton),
              ),
            Expanded(
              child: ClipRect(child: body),
            ),
          ],
        ),
      ),
    );
  }

  static VoidCallback? _extractFabCallback(Widget? fab) {
    if (fab is FloatingActionButton) {
      return fab.onPressed;
    }
    return null;
  }
}

/// 260px wide modern desktop sidebar inspired by Linear & Notion.
class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    this.onQuickAction,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.85),
        border: Border(
          right: BorderSide(color: colors.border.withValues(alpha: 0.55), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                const ArtIcon(
                  size: 38,
                  icon: Icons.account_balance_wallet_rounded,
                  shapeOverride: ArtShape.squircle,
                  showAura: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppConfig.appName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick "+ Catat Transaksi" Action Button
          if (onQuickAction != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Material(
                color: colors.primary,
                borderRadius: BorderRadius.circular(12),
                elevation: 0,
                child: InkWell(
                  onTap: onQuickAction,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Catat Transaksi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 6),

          // Grouped Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: [
                for (final group in NavGroup.values) ...[
                  if (_hasItemsInGroup(group)) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                      child: Text(
                        group.title,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: colors.textTertiary,
                          letterSpacing: 0.9,
                        ),
                      ),
                    ),
                    for (int i = 0; i < destinations.length; i++)
                      if (destinations[i].group == group)
                        _buildNavItem(
                          context,
                          destinations[i],
                          isSelected: selectedIndex == i,
                          onTap: () => onSelect(i),
                        ),
                  ],
                ],
              ],
            ),
          ),

          // Sidebar Footer (Theme switcher & status)
          _buildFooter(context),
        ],
      ),
    );
  }

  bool _hasItemsInGroup(NavGroup group) {
    return destinations.any((d) => d.group == group);
  }

  Widget _buildNavItem(
    BuildContext context,
    AdaptiveDestination item, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: _HoverNavItem(
        isSelected: isSelected,
        onTap: onTap,
        builder: (hovering) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primaryContainer.withValues(alpha: 0.5)
                : hovering
                    ? colors.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Active indicator pill on left edge
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 3,
                height: isSelected ? 18 : 0,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),

              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: hovering && !isSelected ? 1.08 : 1.0,
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? colors.primary : colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.5), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.border.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Offline Ready',
                  style: TextStyle(fontSize: 10.5, color: colors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (Get.isRegistered<ThemeController>())
            _ThemeToggleCompactButton(theme: Get.find<ThemeController>()),
        ],
      ),
    );
  }
}

/// Tracks hover state for a nav item so its background/icon can respond
/// with a short, deliberate transition (see design-system/irsyads/MASTER.md
/// motion principles: short directional transitions, deliberate hover
/// feedback).
class _HoverNavItem extends StatefulWidget {
  const _HoverNavItem({required this.isSelected, required this.onTap, required this.builder});

  final bool isSelected;
  final VoidCallback onTap;
  final Widget Function(bool hovering) builder;

  @override
  State<_HoverNavItem> createState() => _HoverNavItemState();
}

class _HoverNavItemState extends State<_HoverNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.transparent,
          child: widget.builder(_hovering),
        ),
      ),
    );
  }
}

/// Sleek 72px sidebar for tablet/medium window sizes.
class _CompactSidebar extends StatelessWidget {
  const _CompactSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    this.onQuickAction,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.85),
        border: Border(
          right: BorderSide(color: colors.border.withValues(alpha: 0.55), width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const ArtIcon(
            size: 36,
            icon: Icons.account_balance_wallet_rounded,
            shapeOverride: ArtShape.squircle,
            showAura: true,
          ),
          const SizedBox(height: 16),

          if (onQuickAction != null) ...[
            IconButton(
              onPressed: onQuickAction,
              icon: const Icon(Icons.add_circle_rounded),
              color: colors.primary,
              iconSize: 32,
              tooltip: 'Catat Transaksi',
            ),
            const SizedBox(height: 8),
          ],

          const Divider(height: 1, indent: 14, endIndent: 14),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: destinations.length,
              itemBuilder: (context, i) {
                final d = destinations[i];
                final isSelected = selectedIndex == i;
                return Tooltip(
                  message: d.label,
                  preferBelow: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    child: _HoverNavItem(
                      isSelected: isSelected,
                      onTap: () => onSelect(i),
                      builder: (hovering) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primaryContainer
                              : hovering
                                  ? colors.primary.withValues(alpha: 0.06)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 180),
                          scale: hovering && !isSelected ? 1.1 : 1.0,
                          child: Icon(
                            isSelected ? d.selectedIcon : d.icon,
                            color: isSelected ? colors.primary : colors.textSecondary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (Get.isRegistered<ThemeController>()) ...[
            _ThemeToggleCompactButton(theme: Get.find<ThemeController>()),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ThemeToggleCompactButton extends StatelessWidget {
  const _ThemeToggleCompactButton({required this.theme});

  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Obx(() {
      final mode = theme.themeMode.value;
      final isDark = mode == ThemeMode.dark;
      return IconButton(
        icon: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          size: 18,
          color: colors.textSecondary,
        ),
        tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
        onPressed: () {
          theme.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
        },
      );
    });
  }
}

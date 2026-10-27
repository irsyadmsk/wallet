import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:financial_recording/shared/widget/service_brand_icon.dart';

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
/// - tablet/desktop: expandable navigation and a reversible focus mode.
/// Navigation preferences live only in this widget's memory.
class AdaptiveScaffold extends StatefulWidget {
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
    this.beforeFirst,
  });

  final List<AdaptiveDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;
  final Widget body;
  final Widget? floatingActionButton;
  final VoidCallback? onQuickAction;
  final String? appBarTitle;
  final List<Widget>? appBarActions;

  /// Phone swipe target "before" the first bottom-bar page (Beranda),
  /// e.g. Akun: swiping toward the left edge from Beranda lands there.
  final int? beforeFirst;

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  bool? _expandedPreference;
  bool _focusMode = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        _buildLayout(context, constraints.maxWidth),
  );

  Widget _buildLayout(BuildContext context, double width) {
    final c = context.colors;

    if (width < Breakpoints.compact) {
      // While typing, the keyboard covers the bar; don't reserve room for it.
      final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
      return Scaffold(
        backgroundColor: c.surfaceAlt,
        extendBody: true,
        // Pages scroll behind the floating bar, but their own Scaffold FABs
        // and SafeAreas must clear it: report the bar as bottom padding.
        // Without this every page FAB (Kategori, Target, Utang, Memo,
        // Berulang) sat under the bar and couldn't be tapped.
        body: Builder(
          builder: (context) {
            final mq = MediaQuery.of(context);
            final swipeable = _SwipePages(
              destinations: widget.destinations,
              index: widget.index,
              onSelect: widget.onSelect,
              beforeFirst: widget.beforeFirst,
              child: widget.body,
            );
            if (keyboardUp) return swipeable;
            final bottom = _PhoneBar.height + mq.viewPadding.bottom;
            // Scaffold places its FAB from viewPadding, lists and SafeArea
            // read padding — set both.
            return MediaQuery(
              data: mq.copyWith(
                padding: mq.padding.copyWith(
                  bottom: bottom > mq.padding.bottom
                      ? bottom
                      : mq.padding.bottom,
                ),
                viewPadding: mq.viewPadding.copyWith(bottom: bottom),
              ),
              child: swipeable,
            );
          },
        ),
        bottomNavigationBar: _PhoneBar(
          destinations: widget.destinations,
          index: widget.index,
          onSelect: widget.onSelect,
          onQuickAction: widget.onQuickAction,
        ),
      );
    }

    // At narrow tablet widths keep enough room for the page. An explicit
    // desktop preference is retained when resizing back to a wider window.
    final canExpand = width >= Breakpoints.medium;
    final expanded = canExpand && (_expandedPreference ?? width >= 1024);
    final navigation = expanded
        ? _Sidebar(
            destinations: widget.destinations,
            index: widget.index,
            onSelect: widget.onSelect,
            onQuickAction: widget.onQuickAction,
            onCollapse: () => setState(() => _expandedPreference = false),
            onFocus: () => setState(() => _focusMode = true),
          )
        : _Rail(
            destinations: widget.destinations,
            index: widget.index,
            onSelect: widget.onSelect,
            onQuickAction: widget.onQuickAction,
            onExpand: canExpand
                ? () => setState(() => _expandedPreference = true)
                : null,
            onFocus: () => setState(() => _focusMode = true),
          );
    return Scaffold(
      backgroundColor: c.surfaceAlt,
      body: Row(
        children: [
          // Keep the content in the same tree position while toggling, so
          // forms and page-local state are not disposed with the navigation.
          if (!_focusMode) navigation else const SizedBox.shrink(),
          Expanded(
            child: Column(
              children: [
                if (_focusMode)
                  SafeArea(
                    bottom: false,
                    child: Material(
                      color: c.surface,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          8,
                          4,
                          12,
                          4,
                        ),
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  setState(() => _focusMode = false),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              icon: const Icon(Icons.menu_open_rounded),
                              label: const Text('Tampilkan navigasi'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.destinations[widget.index].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Expanded(child: ClipRect(child: widget.body)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ phone

/// One-handed navigation: a quick horizontal swipe anywhere on a page moves
/// along [Akun] ⇄ Beranda ⇄ Transaksi ⇄ Laporan → Semua menu. Horizontal
/// lists, chips and swipeable rows inside the page claim their own drags
/// first, so they keep working.
class _SwipePages extends StatelessWidget {
  const _SwipePages({
    required this.destinations,
    required this.index,
    required this.onSelect,
    required this.child,
    this.beforeFirst,
  });
  final List<AdaptiveDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;
  final int? beforeFirst;
  final Widget child;

  static const _minVelocity = 450.0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      for (var i = 0; i < destinations.length; i++)
        if (destinations[i].showInBottomBar) i,
    ];
    final at = pages.indexOf(index);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() < _minVelocity) return;
        // Finger moving left (v < 0) goes forward, like turning a page.
        final forward = v < 0;
        void go(int page) {
          HapticFeedback.selectionClick();
          onSelect(page);
        }

        // The page left of Beranda: forward returns home.
        if (index == beforeFirst) {
          if (forward) go(pages.first);
          return;
        }
        // Any other page reached from "Lainnya": back goes home.
        if (at < 0) {
          if (!forward) go(pages.first);
          return;
        }
        if (!forward && at == 0) {
          if (beforeFirst != null) go(beforeFirst!);
          return;
        }
        // Past the last bottom-bar page (Laporan): every other menu.
        if (forward && at == pages.length - 1) {
          _showMoreSheet(context, destinations, index, onSelect);
          return;
        }
        go(pages[at + (forward ? 1 : -1)]);
      },
      child: child,
    );
  }
}

/// Phone navigation: one rounded pill holding the bottom-bar pages plus
/// "Lainnya" — the current page as a raised chip with its label, the rest
/// as icons — and a separate round "+" beside it.
class _PhoneBar extends StatelessWidget {
  const _PhoneBar({
    required this.destinations,
    required this.index,
    required this.onSelect,
    this.onQuickAction,
  });

  /// Bar height plus its bottom margin (see build).
  static const double height = 60 + 12;
  final List<AdaptiveDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bar = destinations.where((d) => d.showInBottomBar).toList();
    final inMore = !destinations[index].showInBottomBar;
    const more = AdaptiveDestination(
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      label: 'Lainnya',
    );

    final items = <(AdaptiveDestination, bool, VoidCallback)>[
      for (final d in bar)
        (
          d,
          destinations.indexOf(d) == index,
          () => onSelect(destinations.indexOf(d)),
        ),
      (more, inMore, () => _showMore(context)),
    ];

    // Swipe up on the bar opens every other menu (the same sheet as
    // "Lainnya"); swipe the sheet down anywhere to close it again.
    return _SwipeUpToOpen(
      onOpen: () => _showMore(context),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        c.surfaceAlt,
                        c.textPrimary,
                        dark ? 0.08 : 0.05,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: dark ? 0.3 : 0.08,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        for (final (d, selected, onTap) in items)
                          if (selected)
                            Expanded(
                              child: _BarItem(
                                d: d,
                                selected: true,
                                onTap: onTap,
                              ),
                            )
                          else
                            SizedBox(
                              width: 48,
                              child: _BarItem(
                                d: d,
                                selected: false,
                                onTap: onTap,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
                if (onQuickAction != null) ...[
                  const SizedBox(width: 10),
                  _AddButton(onTap: onQuickAction!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMore(BuildContext context) =>
      _showMoreSheet(context, destinations, index, onSelect);
}

/// "Lainnya" — from the bar's button, a swipe up on the bar, or a forward
/// swipe past Laporan.
void _showMoreSheet(
  BuildContext context,
  List<AdaptiveDestination> destinations,
  int index,
  ValueChanged<int> onSelect,
) {
  HapticFeedback.selectionClick();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 340),
      reverseDuration: Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    ),
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

/// Fires [onOpen] once per gesture when the finger moves up over [child]
/// (a short flick or a slow 24px drag both count).
class _SwipeUpToOpen extends StatefulWidget {
  const _SwipeUpToOpen({required this.onOpen, required this.child});
  final VoidCallback onOpen;
  final Widget child;

  @override
  State<_SwipeUpToOpen> createState() => _SwipeUpToOpenState();
}

class _SwipeUpToOpenState extends State<_SwipeUpToOpen> {
  double _dy = 0;
  bool _fired = false;

  void _fire() {
    if (_fired) return;
    _fired = true;
    widget.onOpen();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onVerticalDragStart: (_) {
      _dy = 0;
      _fired = false;
    },
    onVerticalDragUpdate: (d) {
      _dy += d.primaryDelta ?? 0;
      if (_dy < -24) _fire();
    },
    onVerticalDragEnd: (d) {
      if ((d.primaryVelocity ?? 0) < -250) _fire();
    },
    child: widget.child,
  );
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.d,
    required this.selected,
    required this.onTap,
  });
  final AdaptiveDestination d;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticLabel: d.bottomBarLabel,
        tooltip: selected ? null : d.bottomBarLabel,
        hoverLift: 0,
        pressedScale: 0.92,
        borderRadius: BorderRadius.circular(26),
        builder: (context, s, _) => Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: selected ? 12 : 0),
          decoration: selected
              ? BoxDecoration(
                  color: dark
                      ? Color.lerp(c.surfaceRaised, c.textPrimary, 0.14)
                      : c.surfaceRaised,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.25 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? d.selectedIcon : d.icon,
                size: 22,
                color: selected ? c.textPrimary : c.textSecondary,
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    d.bottomBarLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

/// Round "+" beside the bar — spins a quarter turn while pressed.
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
      pressedScale: 0.9,
      borderRadius: BorderRadius.circular(99),
      builder: (context, s, _) => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: c.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedRotation(
          turns: s.pressed ? 0.25 : 0,
          duration: AppMotion.base,
          curve: AppMotion.emphasized,
          child: Icon(Icons.add_rounded, color: c.onPrimary, size: 30),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

/// "Lainnya": every page not in the bottom bar as a bento of tiles you can
/// nudge around — they drift back with inertia.
class _MoreSheet extends StatelessWidget {
  const _MoreSheet({
    required this.destinations,
    required this.index,
    required this.onSelect,
  });
  final List<AdaptiveDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final more = [
      for (var i = 0; i < destinations.length; i++)
        if (!destinations[i].showInBottomBar) i,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
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
                  child: _Tile(
                    d: destinations[more[k]],
                    selected: more[k] == index,
                    onTap: () => onSelect(more[k]),
                  ),
                ),
              Reveal(
                index: more.length,
                dy: 12,
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
          color: selected
              ? c.textPrimary
              : (s.active ? c.primaryContainer : c.surfaceAlt),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Colors.transparent : c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? d.selectedIcon : d.icon,
              color: selected ? c.surfaceAlt : c.textPrimary,
              size: 24,
            ),
            const Spacer(),
            Text(
              d.bottomBarLabel,
              maxLines: 2,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                height: 1.2,
                color: selected ? c.surfaceAlt : c.textPrimary,
              ),
            ),
            if (d.hint != null)
              Text(
                d.hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? c.surfaceAlt.withValues(alpha: 0.7)
                      : c.textTertiary,
                ),
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
  const _Sidebar({
    required this.destinations,
    required this.index,
    required this.onSelect,
    required this.onCollapse,
    required this.onFocus,
    this.onQuickAction,
  });
  final List<AdaptiveDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback? onQuickAction;
  final VoidCallback onCollapse;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 264,
      decoration: BoxDecoration(
        color: c.surface,
        border: BorderDirectional(end: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 8, 4),
              child: Row(
                children: [
                  const ServiceBrandIcon(service: 'wallet', size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppConfig.appName,
                      maxLines: 2,
                      style: AppTypography.display(
                        size: 24,
                        weight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  WIconButton(
                    icon: Icons.menu_open_rounded,
                    tooltip: 'Ringkas navigasi',
                    size: 48,
                    onPressed: onCollapse,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
              child: TextButton.icon(
                onPressed: onFocus,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  alignment: AlignmentDirectional.centerStart,
                ),
                icon: const Icon(Icons.center_focus_strong_outlined, size: 20),
                label: const Text('Mode fokus'),
              ),
            ),
            if (onQuickAction != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: WButton(
                  label: 'Catat transaksi',
                  icon: Icons.add_rounded,
                  expand: true,
                  onPressed: onQuickAction,
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                children: [
                  for (final g in NavGroup.values) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
                      child: Text(
                        g.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.textTertiary,
                        ),
                      ),
                    ),
                    for (var i = 0; i < destinations.length; i++)
                      if (destinations[i].group == g)
                        _SideItem(
                          d: destinations[i],
                          selected: i == index,
                          onTap: () => onSelect(i),
                        ),
                  ],
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _ServiceEntry(),
            ),
            const _SidebarFooter(),
          ],
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.d,
    required this.selected,
    required this.onTap,
  });
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
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected
                  ? c.textPrimary
                  : (s.active
                        ? c.textPrimary.withValues(alpha: 0.05)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AnimatedSlide(
                  offset: Offset(
                    s.hovered && !selected && !AppMotion.reduced(context)
                        ? (Directionality.of(context) == TextDirection.rtl
                              ? -0.12
                              : 0.12)
                        : 0,
                    0,
                  ),
                  duration: AppMotion.hover,
                  child: Icon(
                    selected ? d.selectedIcon : d.icon,
                    size: 20,
                    color: selected ? c.surfaceAlt : c.textSecondary,
                  ),
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
  const _SidebarFooter({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = Get.find<AuthController>();
    final sync = Get.find<SyncController>();
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(vertical: 8)
          : const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Obx(() {
        final name = auth.displayName;
        final family = sync.household.value;
        final ok = sync.errorText.value == null;
        final status = sync.syncing.value
            ? 'Menyinkronkan…'
            : (ok ? (family == null ? 'Tersinkron' : family.name) : 'Offline');
        if (compact) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: '$name · $status',
                child: Semantics(
                  label: '$name · $status',
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: c.textPrimary,
                          child: Text(
                            name.isEmpty
                                ? '?'
                                : name.characters.first.toUpperCase(),
                            style: TextStyle(
                              color: c.surfaceAlt,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          end: 7,
                          bottom: 7,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: sync.syncing.value
                                  ? c.info
                                  : (ok ? c.success : c.warning),
                              shape: BoxShape.circle,
                              border: Border.all(color: c.surface, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (Get.isRegistered<ThemeController>())
                _ThemeToggle(theme: Get.find<ThemeController>()),
            ],
          );
        }
        return Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: c.textPrimary,
              child: Text(
                name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: TextStyle(
                  color: c.surfaceAlt,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: sync.syncing.value
                              ? c.info
                              : (ok ? c.success : c.warning),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          status,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (Get.isRegistered<ThemeController>())
              _ThemeToggle(theme: Get.find<ThemeController>()),
          ],
        );
      }),
    );
  }
}

// ----------------------------------------------------------------- tablet

class _Rail extends StatelessWidget {
  const _Rail({
    required this.destinations,
    required this.index,
    required this.onSelect,
    required this.onFocus,
    this.onExpand,
    this.onQuickAction,
  });
  final List<AdaptiveDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback? onQuickAction;
  final VoidCallback? onExpand;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: c.surface,
        border: BorderDirectional(end: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const ServiceBrandIcon(service: 'wallet', size: 40),
            if (onExpand != null)
              WIconButton(
                icon: Icons.menu_rounded,
                tooltip: 'Perluas navigasi',
                size: 48,
                onPressed: onExpand,
              ),
            WIconButton(
              icon: Icons.center_focus_strong_outlined,
              tooltip: 'Mode fokus',
              size: 48,
              onPressed: onFocus,
            ),
            const SizedBox(height: 8),
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
                          icon: i == index
                              ? destinations[i].selectedIcon
                              : destinations[i].icon,
                          tooltip: destinations[i].label,
                          size: 48,
                          filled: i == index,
                          color: i == index ? c.primary : c.textSecondary,
                          onPressed: () => onSelect(i),
                        ),
                      ),
                    ),
                  const _ServiceEntry(compact: true),
                  const _SidebarFooter(compact: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One service launcher per desktop navigation, in both presentation modes.
class _ServiceEntry extends StatelessWidget {
  const _ServiceEntry({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return WIconButton(
        icon: Icons.grid_view_rounded,
        tooltip: 'Ruang Irsyads — semua layanan',
        size: 48,
        onPressed: () => Ecosystem.showSwitcher(context),
      );
    }
    return TextButton.icon(
      onPressed: () => Ecosystem.showSwitcher(context),
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        alignment: AlignmentDirectional.centerStart,
      ),
      icon: const Icon(Icons.grid_view_rounded, size: 20),
      label: const Text('Ruang Irsyads'),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.theme});
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dark =
          theme.themeMode.value == ThemeMode.dark ||
          (theme.themeMode.value == ThemeMode.system &&
              MediaQuery.platformBrightnessOf(context) == Brightness.dark);
      return WIconButton(
        icon: dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        tooltip: dark ? 'Mode terang' : 'Mode gelap',
        size: 48,
        onPressed: () =>
            theme.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark),
      );
    });
  }
}

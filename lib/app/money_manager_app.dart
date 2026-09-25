import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/data/services/sync/sync_registry.dart';
import 'package:financial_recording/app/app_events.dart';
import 'package:financial_recording/app/demo_mode.dart';
import 'package:financial_recording/app/shell_controller.dart';
import 'package:financial_recording/app/sync_controller.dart';
import 'package:financial_recording/presentation/auth/view/auth_panel.dart';
import 'package:financial_recording/presentation/auth/view/welcome_view.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/presentation/auth/controller/auth_controller.dart';
import 'package:financial_recording/data/services/pin_lock_service.dart';
import 'package:financial_recording/presentation/pin_lock/view/pin_lock_view.dart';
import 'package:financial_recording/presentation/accounts/controller/accounts_controller.dart';
import 'package:financial_recording/presentation/accounts/view/accounts_view.dart';
import 'package:financial_recording/presentation/budgets/controller/budgets_controller.dart';
import 'package:financial_recording/presentation/budgets/view/budgets_view.dart';
import 'package:financial_recording/presentation/categories/view/categories_view.dart';
import 'package:financial_recording/presentation/dashboard/controller/dashboard_controller.dart';
import 'package:financial_recording/presentation/dashboard/view/dashboard_view.dart';
import 'package:financial_recording/presentation/debts/controller/debts_controller.dart';
import 'package:financial_recording/presentation/debts/view/debts_view.dart';
import 'package:financial_recording/presentation/form_tx/view/form_tx_view.dart';
import 'package:financial_recording/presentation/goals/controller/goals_controller.dart';
import 'package:financial_recording/presentation/goals/view/goals_view.dart';
import 'package:financial_recording/presentation/recurring/view/recurring_view.dart';
import 'package:financial_recording/presentation/family/view/family_view.dart';
import 'package:financial_recording/presentation/reports/controller/reports_controller.dart';
import 'package:financial_recording/presentation/reports/view/reports_view.dart';
import 'package:financial_recording/presentation/zakat/view/zakat_view.dart';
import 'package:financial_recording/presentation/settings/view/settings_view.dart';
import 'package:financial_recording/presentation/transactions/controller/transactions_controller.dart';
import 'package:financial_recording/presentation/transactions/view/transactions_view.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/adaptive_scaffold.dart';
import 'package:financial_recording/shared/theme/app_theme.dart';
import 'package:financial_recording/shared/theme/theme_controller.dart';

class MoneyManagerApp extends StatelessWidget {
  const MoneyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.put(ThemeController(), permanent: true);
    Get.put(ShellController(), permanent: true);
    Get.put(SyncController(), permanent: true);
    Get.put(AuthController(), permanent: true);

    return Obx(() => GetMaterialApp(
          title: AppConfig.appName,
          navigatorKey: Get.key,
          locale: const Locale('id', 'ID'),
          fallbackLocale: const Locale('en', 'US'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(theme.seedColor.value),
          darkTheme: AppTheme.dark(theme.seedColor.value),
          themeMode: theme.themeMode.value,
          home: const _AuthGate(),
        ));
  }
}

/// Signing in is required: until there's a session the welcome screen is
/// the whole app. A password-reset link lands on [SetNewPasswordView].
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final signedIn = auth.isSignedIn; // always read, so Obx has a dependency
      final Widget page;
      if (kDemoMode) {
        page = const _AppLockGate(key: ValueKey('demo'));
      } else if (!signedIn) {
        page = const WelcomeView(key: ValueKey('welcome'));
      } else if (auth.recoveringPassword.value) {
        page = const SetNewPasswordView(key: ValueKey('recover'));
      } else {
        page = _AppLockGate(key: ValueKey('app-${auth.user.value!.id}'));
      }
      return AnimatedSwitcher(
        duration: AppMotion.of(context, const Duration(milliseconds: 600)),
        switchInCurve: AppMotion.emphasized,
        child: page,
      );
    });
  }
}

/// Shows [PinLockView] once per app launch when the user has enabled a PIN,
/// then hands off to [HomeShell] for the rest of the session.
class _AppLockGate extends StatefulWidget {
  const _AppLockGate({super.key});

  @override
  State<_AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<_AppLockGate> {
  late bool _unlocked = !PinLockService().isEnabled;

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return const HomeShell();
    return PinLockView(onUnlocked: () => setState(() => _unlocked = true));
  }
}

const _destinations = [
  AdaptiveDestination(
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard_rounded,
    label: 'Beranda',
  ),
  AdaptiveDestination(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    label: 'Transaksi',
  ),
  AdaptiveDestination(
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet_rounded,
    label: 'Akun & Saldo',
    shortLabel: 'Akun',
    hint: 'Rekening & dompet',
    showInBottomBar: false,
  ),
  AdaptiveDestination(
    icon: Icons.pie_chart_outline_rounded,
    selectedIcon: Icons.pie_chart_rounded,
    label: 'Anggaran',
    hint: 'Batas bulanan',
    showInBottomBar: false,
  ),
  AdaptiveDestination(
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
    label: 'Laporan',
  ),
  AdaptiveDestination(
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag_rounded,
    label: 'Target Tabungan',
    shortLabel: 'Target',
    hint: 'Impian & progres',
    showInBottomBar: false,
    group: NavGroup.plans,
  ),
  AdaptiveDestination(
    icon: Icons.handshake_outlined,
    selectedIcon: Icons.handshake_rounded,
    label: 'Utang & Piutang',
    shortLabel: 'Utang',
    hint: 'Pinjaman & cicilan',
    showInBottomBar: false,
    group: NavGroup.plans,
  ),
  AdaptiveDestination(
    icon: Icons.autorenew_rounded,
    selectedIcon: Icons.autorenew_rounded,
    label: 'Transaksi Berulang',
    shortLabel: 'Berulang',
    hint: 'Gaji, tagihan',
    showInBottomBar: false,
    group: NavGroup.plans,
  ),
  AdaptiveDestination(
    icon: Icons.volunteer_activism_outlined,
    selectedIcon: Icons.volunteer_activism_rounded,
    label: 'Zakat',
    hint: 'Penghasilan, mal, fitrah',
    showInBottomBar: false,
    group: NavGroup.plans,
  ),
  AdaptiveDestination(
    icon: Icons.diversity_3_outlined,
    selectedIcon: Icons.diversity_3_rounded,
    label: 'Keluarga',
    hint: 'Buku kas bersama',
    showInBottomBar: false,
    group: NavGroup.system,
  ),
  AdaptiveDestination(
    icon: Icons.category_outlined,
    selectedIcon: Icons.category_rounded,
    label: 'Kategori',
    hint: 'Pemasukan & belanja',
    showInBottomBar: false,
    group: NavGroup.system,
  ),
  AdaptiveDestination(
    icon: Icons.tune_outlined,
    selectedIcon: Icons.tune_rounded,
    label: 'Pengaturan',
    hint: 'Akun, tema, cadangan',
    showInBottomBar: false,
    group: NavGroup.system,
  ),
];

// Order must match [AppPage].
const _screens = [
  DashboardView(),
  TransactionsView(),
  AccountsView(),
  BudgetsView(),
  ReportsView(),
  GoalsView(),
  DebtsView(),
  RecurringView(),
  ZakatView(),
  FamilyView(),
  CategoriesView(),
  SettingsView(),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _shell = Get.find<ShellController>();
  late final Worker _dataWorker;
  late final Worker _pageWorker;
  final _boxSubs = <StreamSubscription>[];

  /// Bumped on every data change. A page whose controller last refreshed at
  /// an older version is stale and reloads when it's opened again, so a
  /// change never recomputes every screen that happens to be alive.
  int _version = 0;
  final _seenVersion = <int, int>{};

  @override
  void initState() {
    super.initState();
    // A sync pulled rows or the ledger switched: reload the open screen.
    _dataWorker = ever(dataVersion, (_) => _invalidate());
    _pageWorker = ever<int>(_shell.selectedIndex, (i) {
      if ((_seenVersion[i] ?? 0) != _version) _refreshPage(i);
    });
    // Local edits: the screen that made them already refreshes itself, so
    // only mark the others stale.
    for (final box in openFinancialBoxes()) {
      _boxSubs.add(box.watch().listen((_) {
        _version++;
        _seenVersion[_shell.selectedIndex.value] = _version;
      }));
    }
  }

  @override
  void dispose() {
    _dataWorker.dispose();
    _pageWorker.dispose();
    for (final s in _boxSubs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = _shell;
    return Obx(() {
      final index = shell.selectedIndex.value;
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      return AdaptiveScaffold(
        destinations: _destinations,
        index: index,
        onSelect: shell.goTo,
        onQuickAction: () => _openAddTransaction(context),
        body: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 360),
          switchInCurve: AppMotion.emphasized,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.topLeft,
            children: [...previousChildren, if (currentChild != null) currentChild],
          ),
          child: KeyedSubtree(key: ValueKey(index), child: _screens[index]),
        ),
      );
    });
  }

  Future<void> _openAddTransaction(BuildContext context) async {
    final saved = await showAdaptiveSheet<bool>(context, builder: (_) => const FormTxView());
    if (saved == true) _invalidate();
  }

  void _invalidate() {
    _version++;
    _refreshPage(_shell.selectedIndex.value);
  }

  void _refreshPage(int page) {
    _seenVersion[page] = _version;
    switch (page) {
      case AppPage.dashboard:
        if (Get.isRegistered<DashboardController>(tag: 'dashboard')) {
          Get.find<DashboardController>(tag: 'dashboard').refresh();
        }
      case AppPage.transactions:
        if (Get.isRegistered<TransactionsController>(tag: 'transactions')) {
          Get.find<TransactionsController>(tag: 'transactions').refresh();
        }
      case AppPage.accounts:
        if (Get.isRegistered<AccountsController>(tag: 'accounts')) {
          Get.find<AccountsController>(tag: 'accounts').refresh();
        }
      case AppPage.budgets:
        if (Get.isRegistered<BudgetsController>(tag: 'budgets')) {
          Get.find<BudgetsController>(tag: 'budgets').refresh();
        }
      case AppPage.goals:
        if (Get.isRegistered<GoalsController>()) {
          Get.find<GoalsController>().refresh();
        }
      case AppPage.debts:
        if (Get.isRegistered<DebtsController>(tag: 'debts')) {
          Get.find<DebtsController>(tag: 'debts').load();
        }
      case AppPage.reports:
        if (Get.isRegistered<ReportsController>(tag: 'reports')) {
          Get.find<ReportsController>(tag: 'reports').refresh();
        }
    }
  }
}

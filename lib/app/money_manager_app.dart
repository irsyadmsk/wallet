import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/app/shell_controller.dart';
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
import 'package:financial_recording/presentation/reports/view/reports_view.dart';
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
          home: const _AppLockGate(),
        ));
  }
}

/// Shows [PinLockView] once per app launch when the user has enabled a PIN,
/// then hands off to [HomeShell] for the rest of the session.
class _AppLockGate extends StatefulWidget {
  const _AppLockGate();

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
  // UTAMA
  AdaptiveDestination(
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard_rounded,
    label: 'Beranda',
    group: NavGroup.main,
  ),
  AdaptiveDestination(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    label: 'Transaksi',
    group: NavGroup.main,
  ),
  AdaptiveDestination(
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet_rounded,
    label: 'Akun & Saldo',
    shortLabel: 'Akun',
    group: NavGroup.main,
  ),
  AdaptiveDestination(
    icon: Icons.pie_chart_outline_rounded,
    selectedIcon: Icons.pie_chart_rounded,
    label: 'Anggaran',
    group: NavGroup.main,
  ),
  AdaptiveDestination(
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
    label: 'Laporan Analisis',
    shortLabel: 'Laporan',
    group: NavGroup.main,
  ),

  // ASET & RENCANA
  AdaptiveDestination(
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag_rounded,
    label: 'Target Tabungan',
    showInBottomBar: false,
    group: NavGroup.plans,
  ),
  AdaptiveDestination(
    icon: Icons.handshake_outlined,
    selectedIcon: Icons.handshake_rounded,
    label: 'Utang & Piutang',
    showInBottomBar: false,
    group: NavGroup.plans,
  ),
  AdaptiveDestination(
    icon: Icons.autorenew_rounded,
    selectedIcon: Icons.autorenew_rounded,
    label: 'Transaksi Berulang',
    showInBottomBar: false,
    group: NavGroup.plans,
  ),

  // PENGATURAN
  AdaptiveDestination(
    icon: Icons.category_outlined,
    selectedIcon: Icons.category_rounded,
    label: 'Kategori Transaksi',
    showInBottomBar: false,
    group: NavGroup.system,
  ),
  AdaptiveDestination(
    icon: Icons.tune_outlined,
    selectedIcon: Icons.tune_rounded,
    label: 'Pengaturan',
    showInBottomBar: false,
    group: NavGroup.system,
  ),
];

const _screens = [
  DashboardView(),
  TransactionsView(),
  AccountsView(),
  BudgetsView(),
  ReportsView(),
  GoalsView(),
  DebtsView(),
  RecurringView(),
  CategoriesView(),
  SettingsView(),
];

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = Get.find<ShellController>();
    return Obx(() {
      final index = shell.selectedIndex.value;
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      return AdaptiveScaffold(
        destinations: _destinations,
        index: index,
        onSelect: shell.goTo,
        onQuickAction: () => _openAddTransaction(context),
        body: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.015), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.topLeft,
            children: [...previousChildren, if (currentChild != null) currentChild],
          ),
          child: KeyedSubtree(key: ValueKey(index), child: _screens[index]),
        ),
        floatingActionButton: index <= 1
            ? FloatingActionButton(
                onPressed: () => _openAddTransaction(context),
                child: const Icon(Icons.add_rounded),
              )
            : null,
      );
    });
  }

  Future<void> _openAddTransaction(BuildContext context) async {
    final saved = await showAdaptiveSheet<bool>(context, builder: (_) => const FormTxView());
    if (saved == true) _refreshAllScreens();
  }

  void _refreshAllScreens() {
    if (Get.isRegistered<DashboardController>(tag: 'dashboard')) {
      Get.find<DashboardController>(tag: 'dashboard').refresh();
    }
    if (Get.isRegistered<TransactionsController>(tag: 'transactions')) {
      Get.find<TransactionsController>(tag: 'transactions').refresh();
    }
    if (Get.isRegistered<AccountsController>(tag: 'accounts')) {
      Get.find<AccountsController>(tag: 'accounts').refresh();
    }
    if (Get.isRegistered<BudgetsController>(tag: 'budgets')) {
      Get.find<BudgetsController>(tag: 'budgets').refresh();
    }
    if (Get.isRegistered<GoalsController>()) {
      Get.find<GoalsController>().refresh();
    }
    if (Get.isRegistered<DebtsController>(tag: 'debts')) {
      Get.find<DebtsController>(tag: 'debts').load();
    }
  }
}

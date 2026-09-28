import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/presentation/emoney_nfc/view/emoney_nfc_view.dart';
import 'package:financial_recording/data/services/emoney_nfc_service.dart';
import 'package:financial_recording/shared/widget/market_card.dart';
import 'package:financial_recording/data/services/currency/currency_service.dart';
import 'package:financial_recording/app/shell_controller.dart';
import 'package:financial_recording/app/sync_controller.dart';
import 'package:financial_recording/data/services/budget_service_v2.dart';
import 'package:financial_recording/presentation/account_detail/view/account_detail_view.dart';
import 'package:financial_recording/presentation/accounts/widget/account_editor_sheet.dart';
import 'package:financial_recording/presentation/auth/controller/auth_controller.dart';
import 'package:financial_recording/presentation/dashboard/controller/dashboard_controller.dart';
import 'package:financial_recording/presentation/form_tx/view/form_tx_view.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/breakpoints.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/shared/widget/account_card_stack.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';
import 'package:financial_recording/shared/widget/quick_template_bar.dart';
import 'package:financial_recording/shared/widget/tx_tile.dart';
import 'package:financial_recording/util/money/money_format.dart';
import 'package:financial_recording/data/services/currency/display_currency.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DashboardController(), tag: 'dashboard');
    final shell = Get.find<ShellController>();
    final wide = context.windowSize == WindowSize.expanded || context.windowSize == WindowSize.large;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            Get.find<SyncController>().syncNow(),
            CurrencyService.instance.refresh(force: true),
          ]);
          c.refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: SafeArea(
            bottom: false,
            child: ContentShell(
              child: Obx(() {
                var i = 0;
                // Money first, then what needs doing, then the details — the
                // score and narrative live on Laporan.
                final hero = Reveal(
                  index: i++,
                  child: _NetWorthCard(
                    controller: c,
                    hidden: _hidden,
                    onToggle: () => setState(() => _hidden = !_hidden),
                    onBudget: () => shell.goTo(AppPage.budgets),
                  ),
                );
                final attention = <Widget>[
                  // Only for ledgers holding gold or foreign money: the rates
                  // behind the rupiah total.
                  if (CurrencyService.instance.hasForeignAccounts) ...[
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: MarketCard(compact: true)),
                    const SizedBox(height: 12),
                  ],
                  if (c.upcomingRecurring.isNotEmpty) ...[
                    Reveal(index: i++, child: _UpcomingCard(controller: c)),
                    const SizedBox(height: 12),
                  ],
                  if (c.activeDebtCount.value > 0) ...[
                    Reveal(index: i++, child: _DebtStrip(controller: c, onTap: () => shell.goTo(AppPage.debts))),
                    const SizedBox(height: 12),
                  ],
                ];
                final templates = <Widget>[
                  if (c.templates.isNotEmpty) ...[
                    Reveal(index: i++, child: QuickTemplateBar(templates: c.templates, onRecorded: c.refresh)),
                    const SizedBox(height: 24),
                  ],
                ];
                final recent = Reveal(
                  index: i++,
                  child: _RecentSection(controller: c, onSeeAll: () => shell.goTo(AppPage.transactions)),
                );
                final accounts = Reveal(index: i++, child: _AccountsSection(controller: c, hidden: _hidden));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Greeting(),
                    const SizedBox(height: 16),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [hero, const SizedBox(height: 24), recent],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [...attention, ...templates, accounts],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      hero,
                      const SizedBox(height: 16),
                      ...attention,
                      ...templates,
                      recent,
                      const SizedBox(height: 24),
                      accounts,
                    ],
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  static String _salam(int h) {
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = Get.find<AuthController>();
    final sync = Get.find<SyncController>();
    final now = DateTime.now();
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_salam(now.hour)} · ${DateFormat('EEEE, d MMM', 'id_ID').format(now)}',
                    style: TextStyle(color: c.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    auth.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.headlineSmall,
                  ),
                ],
              )),
        ),
        // One tap from home: read an e-money card's balance over NFC.
        if (EmoneyNfcService.isSupported)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () async {
                final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const EmoneyNfcView()));
                if (created == true && Get.isRegistered<DashboardController>(tag: 'dashboard')) {
                  Get.find<DashboardController>(tag: 'dashboard').refresh();
                }
              },
              icon: const Icon(Icons.contactless_rounded, size: 20),
              label: const Text('Cek kartu'),
            ),
          ),
        Obx(() {
          final syncing = sync.syncing.value;
          final err = sync.errorText.value;
          return WIconButton(
            icon: syncing ? Icons.sync_rounded : (err == null ? Icons.cloud_done_outlined : Icons.cloud_off_outlined),
            tooltip: syncing ? 'Menyinkronkan…' : (err ?? 'Tersinkron — ketuk untuk sinkron sekarang'),
            color: err == null ? c.textSecondary : c.warning,
            onPressed: syncing ? null : sync.syncNow,
          );
        }),
        WIconButton(
          icon: Icons.tune_rounded,
          tooltip: 'Pengaturan',
          onPressed: () => Get.find<ShellController>().goTo(AppPage.settings),
        ),
      ],
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.controller, required this.hidden, required this.onToggle, required this.onBudget});
  final DashboardController controller;
  final bool hidden;
  final VoidCallback onToggle;
  final VoidCallback onBudget;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const ink = Color(0xFF17272B);
    const cream = AppColors.cream;
    final muted = cream.withValues(alpha: 0.68);
    final m = controller;
    final liabilities = m.totalLiabilities.value.abs();
    final budget = m.overallBudget.value;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? c.surfaceRaised : ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tap to read the total in another currency (dolar, emas, ...).
              Pressable(
                onTap: () => DisplayCurrency.pick(context, previewIdr: m.netWorth.value),
                semanticLabel: 'Ganti mata uang total',
                tooltip: 'Ganti mata uang total',
                hoverLift: 0,
                borderRadius: BorderRadius.circular(99),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ValueListenableBuilder<String>(
                    valueListenable: DisplayCurrency.code,
                    builder: (context, code, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Saldo total · $code', style: TextStyle(color: muted, fontSize: 13.5)),
                        Icon(Icons.expand_more_rounded, size: 18, color: muted),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Pressable(
                onTap: onToggle,
                semanticLabel: hidden ? 'Tampilkan saldo' : 'Sembunyikan saldo',
                tooltip: hidden ? 'Tampilkan saldo' : 'Sembunyikan saldo',
                hoverLift: 0,
                borderRadius: BorderRadius.circular(99),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: muted),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedMoney(
                value: m.netWorth.value,
                hidden: hidden,
                inDisplayCurrency: true,
                style: AppTypography.display(size: 40, weight: FontWeight.w500, color: cream),
              ),
            ),
          ),
          if (liabilities > 0 && !hidden)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Aset ${DisplayCurrency.format(m.totalAssets.value)} · Utang ${DisplayCurrency.format(liabilities)}',
                style: TextStyle(color: muted, fontSize: 12.5),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Figure(
                  label: 'Masuk bulan ini',
                  icon: Icons.south_west_rounded,
                  value: m.monthIncome.value,
                  hidden: hidden,
                  color: cream,
                  muted: muted,
                ),
              ),
              Expanded(
                child: _Figure(
                  label: 'Keluar bulan ini',
                  icon: Icons.north_east_rounded,
                  value: m.monthExpense.value,
                  hidden: hidden,
                  color: cream,
                  muted: muted,
                ),
              ),
            ],
          ),
          if (budget != null && budget.limit > 0) ...[
            const SizedBox(height: 14),
            _BudgetLine(budget: budget, hidden: hidden, cream: cream, muted: muted, onTap: onBudget),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.icon,
    required this.value,
    required this.hidden,
    required this.color,
    required this.muted,
  });
  final String label;
  final IconData icon;
  final int value;
  final bool hidden;
  final Color color;
  final Color muted;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: muted),
              const SizedBox(width: 4),
              Flexible(child: Text(label, style: TextStyle(color: muted, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedMoney(value: value, hidden: hidden, style: AppTypography.numeric(size: 16, weight: FontWeight.w600, color: color)),
          ),
        ],
      );
}

/// This month's overall budget as one line inside the hero card.
class _BudgetLine extends StatelessWidget {
  const _BudgetLine({required this.budget, required this.hidden, required this.cream, required this.muted, required this.onTap});
  final BudgetProgress budget;
  final bool hidden;
  final Color cream;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final b = budget;
    final bar = b.isOver ? c.budgetOver : (b.isNearLimit ? c.budgetWarn : cream);
    final left = b.limit - b.spent;
    final pct = '${(b.percent * 100).clamp(0, 999).toStringAsFixed(0)}%';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(right: 8, top: 2, bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hidden
                        ? 'Anggaran bulan ini $pct terpakai'
                        : (left >= 0 ? 'Sisa anggaran ${left.rupiah}' : 'Anggaran terlampaui ${(-left).rupiah}'),
                    style: TextStyle(color: b.isOver ? bar : cream, fontSize: 13),
                  ),
                ),
                Text(pct, style: AppTypography.numeric(size: 13, weight: FontWeight.w600, color: muted)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: b.percent.clamp(0, 1).toDouble(),
                minHeight: 5,
                color: bar,
                backgroundColor: cream.withValues(alpha: 0.14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
          ],
        ),
      );
}

class _AccountsSection extends StatelessWidget {
  const _AccountsSection({required this.controller, required this.hidden});
  final DashboardController controller;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final accounts = controller.accountsList.where((a) => !a.isArchived).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Rekening & dompet',
          action: accounts.isEmpty ? null : 'Semua akun',
          onAction: () => Get.find<ShellController>().goTo(AppPage.accounts),
        ),
        Padding(
          // Room above for the tabs' shadows.
          padding: const EdgeInsets.only(top: 4),
          child: AccountCardStack(
            accounts: accounts,
            hideBalance: hidden,
            onTapAccount: (acc) async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => AccountDetailView(accountId: acc.id)));
              controller.refresh();
            },
            onAddAccount: () async {
              final result = await showAdaptiveSheet<AccountEditorResult>(context, builder: (_) => const AccountEditorSheet());
              if (result?.saved != null) {
                await controller.accounts.upsert(result!.saved!);
                controller.refresh();
              }
            },
          ),
        ),
      ],
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection({required this.controller, required this.onSeeAll});
  final DashboardController controller;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Transaksi terbaru', action: 'Lihat semua', onAction: onSeeAll),
        Card(
          child: controller.recentTransactions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('Belum ada transaksi', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Catat yang pertama dengan tombol +.', style: TextStyle(color: c.textSecondary)),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      for (final tx in controller.recentTransactions)
                        TxTile(
                          tx: tx,
                          onTap: () async {
                            final saved = await showAdaptiveSheet<bool>(context, builder: (_) => FormTxView(existing: tx));
                            if (saved == true) controller.refresh();
                          },
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jatuh tempo 7 hari ke depan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            for (final r in controller.upcomingRecurring)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.event_repeat_rounded, size: 20, color: c.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.memo?.isNotEmpty == true ? r.memo! : 'Transaksi berulang', style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(DateFormat('EEEE, d MMM', 'id_ID').format(r.nextRunDate), style: TextStyle(fontSize: 12, color: c.textSecondary)),
                        ],
                      ),
                    ),
                    WButton(
                      label: 'Catat ${r.amount.compact}',
                      size: WButtonSize.small,
                      variant: WButtonVariant.outline,
                      tooltip: 'Catat ${r.amount.rupiah} sekarang',
                      onPressed: () => controller.confirmRecurring(r.id),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DebtStrip extends StatelessWidget {
  const _DebtStrip({required this.controller, required this.onTap});
  final DashboardController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Buka utang dan piutang',
      borderRadius: BorderRadius.circular(16),
      builder: (context, s, _) => AnimatedContainer(
        duration: AppMotion.hover,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: s.active ? c.textPrimary.withValues(alpha: 0.4) : c.border),
        ),
        child: Row(
          children: [
            Icon(Icons.handshake_outlined, color: c.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${controller.activeDebtCount.value} utang & piutang aktif', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    'Utang ${controller.activeDebtAmount.value.rupiah} · Piutang ${controller.activeLoanAmount.value.rupiah}',
                    style: TextStyle(fontSize: 12.5, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.textTertiary),
          ],
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

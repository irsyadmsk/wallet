import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/app/shell_controller.dart';
import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/presentation/account_detail/view/account_detail_view.dart';
import 'package:financial_recording/presentation/accounts/widget/account_editor_sheet.dart';
import 'package:financial_recording/presentation/auth/controller/auth_controller.dart';
import 'package:financial_recording/presentation/auth/view/auth_sheet.dart';
import 'package:financial_recording/presentation/dashboard/controller/dashboard_controller.dart';
import 'package:financial_recording/presentation/form_tx/view/form_tx_view.dart';
import 'package:financial_recording/presentation/goals/view/goals_view.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/adaptive_grid.dart';
import 'package:financial_recording/shared/responsive/breakpoints.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/account_card_stack.dart';
import 'package:financial_recording/shared/widget/art_icon.dart';
import 'package:financial_recording/shared/widget/health_score_card.dart';
import 'package:financial_recording/shared/widget/quick_template_bar.dart';
import 'package:financial_recording/shared/widget/section_card.dart';
import 'package:financial_recording/shared/widget/tx_tile.dart';
import 'package:financial_recording/util/money/money_format.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DashboardController(), tag: 'dashboard');
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(AppConfig.appName),
        actions: [
          Obx(() {
            final auth = Get.find<AuthController>();
            return IconButton(
              tooltip: auth.isSignedIn ? (auth.user.value?.email ?? 'Akun') : 'Masuk / Daftar untuk sinkronisasi',
              icon: Icon(
                auth.isSignedIn ? Icons.cloud_done_rounded : Icons.account_circle_outlined,
                color: auth.isSignedIn ? colors.primary : null,
              ),
              onPressed: () {
                if (auth.isSignedIn) {
                  Get.find<ShellController>().goTo(8);
                } else {
                  showAdaptiveSheet<bool>(context, builder: (_) => const AuthSheet());
                }
              },
            );
          }),
          IconButton(
            tooltip: 'Target Finansial',
            icon: const Icon(Icons.flag_rounded),
            onPressed: () async {
              await Get.to(() => const GoalsView());
              c.refresh();
            },
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Get.find<ShellController>().goTo(8),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => c.refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ContentShell(
            child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NetWorthCard(controller: c),
                    const SizedBox(height: AppSpacing.lg),
                    _BankCardsCarousel(controller: c),
                    const SizedBox(height: AppSpacing.lg),
                    if (c.templates.isNotEmpty) ...[
                      QuickTemplateBar(
                        templates: c.templates,
                        onRecorded: c.refresh,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (c.healthReport.value != null) ...[
                      HealthScoreCard(report: c.healthReport.value!),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    AdaptiveGrid(
                      columnsOverride: context.isCompact ? 1 : 2,
                      children: [
                        _CashflowCard(controller: c),
                        _BudgetOverviewCard(controller: c),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (c.activeDebtCount.value > 0) ...[
                      InkWell(
                        onTap: () => Get.find<ShellController>().goTo(6),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: colors.surfaceRaised.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              ArtIcon(
                                size: 38,
                                icon: Icons.handshake_rounded,
                                iconColor: colors.primary,
                                backgroundColor: colors.primaryContainer.withValues(alpha: 0.35),
                                borderColor: colors.primary.withValues(alpha: 0.25),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Utang & Piutang Aktif',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: colors.primaryContainer,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${c.activeDebtCount.value}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: colors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Utang: ${c.activeDebtAmount.value.rupiah}  ·  Piutang: ${c.activeLoanAmount.value.rupiah}',
                                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: colors.textTertiary, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (c.upcomingRecurring.isNotEmpty) ...[
                      SectionCard(
                        title: 'Jatuh tempo minggu ini',
                        child: Column(
                          children: [
                            for (final r in c.upcomingRecurring)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.event_repeat_rounded, color: colors.warning),
                                title: Text(r.memo?.isNotEmpty == true ? r.memo! : 'Transaksi berulang'),
                                subtitle: Text('Jatuh tempo ${DateFormat('d MMM', 'id_ID').format(r.nextRunDate)}'),
                                trailing: TextButton(
                                  onPressed: () async {
                                    await c.confirmRecurring(r.id);
                                  },
                                  child: Text(r.amount.rupiah),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    SectionCard(
                      title: 'Transaksi terbaru',
                      trailing: TextButton(
                        onPressed: () => Get.find<ShellController>().goTo(1),
                        child: const Text('Lihat semua'),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: c.recentTransactions.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: Text('Belum ada transaksi.'),
                            )
                          : Column(
                              children: [
                                for (final tx in c.recentTransactions)
                                  TxTile(
                                    tx: tx,
                                    onTap: () async {
                                      final saved = await showAdaptiveSheet<bool>(
                                        context,
                                        builder: (_) => FormTxView(existing: tx),
                                      );
                                      if (saved == true) c.refresh();
                                    },
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ))
                .animate()
                .fadeIn(duration: _entranceDuration(context), curve: Curves.easeOut)
                .slideY(begin: 0.02, end: 0, duration: _entranceDuration(context), curve: Curves.easeOut),
          ),
        ),
      ),
    );
  }

  /// One staged opening on entry — skipped (zero-duration) when the user
  /// has reduced-motion accessibility settings enabled.
  Duration _entranceDuration(BuildContext context) =>
      (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ? Duration.zero : const Duration(milliseconds: 320);
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, Color.lerp(colors.primary, Colors.black, 0.25)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kekayaan bersih', style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.8))),
          const SizedBox(height: 6),
          Text(
            controller.netWorth.value.rupiah,
            style: TextStyle(color: colors.onPrimary, fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Aset',
                  value: controller.totalAssets.value.rupiah,
                  color: colors.onPrimary,
                ),
              ),
              Container(width: 1, height: 32, color: colors.onPrimary.withValues(alpha: 0.25)),
              Expanded(
                child: _MiniStat(
                  label: 'Liabilitas',
                  value: controller.totalLiabilities.value.rupiah,
                  color: colors.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.75), fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CashflowCard extends StatelessWidget {
  const _CashflowCard({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SectionCard(
      title: 'Bulan ini',
      child: Row(
        children: [
          Expanded(
            child: _FlowStat(
              icon: Icons.arrow_downward_rounded,
              label: 'Pemasukan',
              value: controller.monthIncome.value.rupiah,
              color: colors.income,
            ),
          ),
          Expanded(
            child: _FlowStat(
              icon: Icons.arrow_upward_rounded,
              label: 'Pengeluaran',
              value: controller.monthExpense.value.rupiah,
              color: colors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStat extends StatelessWidget {
  const _FlowStat({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
        ]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}

class _BudgetOverviewCard extends StatelessWidget {
  const _BudgetOverviewCard({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final b = controller.overallBudget.value;
    if (b == null || b.limit <= 0) {
      return SectionCard(
        title: 'Anggaran bulanan',
        trailing: TextButton(
          onPressed: () => Get.find<ShellController>().goTo(3),
          child: const Text('Atur'),
        ),
        child: Text('Belum ada anggaran diset.', style: TextStyle(color: colors.textSecondary)),
      );
    }
    final progressColor = b.isOver ? colors.budgetOver : (b.isNearLimit ? colors.budgetWarn : colors.budgetSafe);
    return SectionCard(
      title: 'Anggaran bulanan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: b.percent.clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${b.spent.rupiah} dari ${b.limit.rupiah}', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BankCardsCarousel extends StatelessWidget {
  const _BankCardsCarousel({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accounts = controller.accountsList.where((a) => !a.isArchived).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card_rounded, size: 18, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  'Kartu Rekening & Dompet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            if (accounts.isNotEmpty)
              TextButton(
                onPressed: () => Get.find<ShellController>().goTo(2),
                child: const Text('Lihat semua'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AccountCardStack(
          accounts: accounts,
          onTapAccount: (acc) async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AccountDetailView(accountId: acc.id)),
            );
            controller.refresh();
          },
          onAddAccount: () async {
            final result = await showAdaptiveSheet<AccountEditorResult>(
              context,
              builder: (_) => const AccountEditorSheet(),
            );
            if (result?.saved != null) {
              await controller.accounts.upsert(result!.saved!);
              controller.refresh();
            }
          },
        ),
      ],
    );
  }
}


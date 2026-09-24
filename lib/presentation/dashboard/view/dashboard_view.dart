import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/app/shell_controller.dart';
import 'package:financial_recording/app/sync_controller.dart';
import 'package:financial_recording/data/services/smart_report_service.dart';
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
import 'package:financial_recording/shared/widget/health_score_card.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';
import 'package:financial_recording/shared/widget/quick_template_bar.dart';
import 'package:financial_recording/shared/widget/tx_tile.dart';
import 'package:financial_recording/util/money/money_format.dart';

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
          await Get.find<SyncController>().syncNow();
          c.refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SafeArea(
            bottom: false,
            child: ContentShell(
              child: Obx(() {
                var i = 0;
                final hero = Reveal(
                  index: i++,
                  child: _NetWorthCard(controller: c, hidden: _hidden, onToggle: () => setState(() => _hidden = !_hidden)),
                );
                final insight = Reveal(index: i++, child: const _InsightTeaser());
                final left = <Widget>[
                  Reveal(index: i++, child: _AccountsSection(controller: c)),
                  const SizedBox(height: 28),
                  if (c.templates.isNotEmpty) ...[
                    Reveal(index: i++, child: QuickTemplateBar(templates: c.templates, onRecorded: c.refresh)),
                    const SizedBox(height: 28),
                  ],
                  Reveal(index: i++, child: _RecentSection(controller: c, onSeeAll: () => shell.goTo(AppPage.transactions))),
                ];
                final right = <Widget>[
                  Reveal(index: i++, child: _BudgetCard(controller: c, onSet: () => shell.goTo(AppPage.budgets))),
                  if (c.healthReport.value != null) ...[
                    const SizedBox(height: 16),
                    Reveal(index: i++, child: HealthScoreCard(report: c.healthReport.value!)),
                  ],
                  if (c.upcomingRecurring.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Reveal(index: i++, child: _UpcomingCard(controller: c)),
                  ],
                  if (c.activeDebtCount.value > 0) ...[
                    const SizedBox(height: 16),
                    Reveal(index: i++, child: _DebtStrip(controller: c, onTap: () => shell.goTo(AppPage.debts))),
                  ],
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Greeting(),
                    const SizedBox(height: 20),
                    if (wide)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [Expanded(flex: 7, child: hero), const SizedBox(width: 16), Expanded(flex: 5, child: insight)],
                        ),
                      )
                    else ...[
                      hero,
                      const SizedBox(height: 16),
                      insight,
                    ],
                    const SizedBox(height: 28),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left)),
                          const SizedBox(width: 16),
                          Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right)),
                        ],
                      )
                    else ...[
                      ...right,
                      const SizedBox(height: 28),
                      ...left,
                    ],
                    const SizedBox(height: 96),
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
                  Text(DateFormat('EEEE, d MMMM', 'id_ID').format(now), style: TextStyle(color: c.textSecondary, fontSize: 13.5)),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${_salam(now.hour)}, ', style: t.headlineMedium),
                      TextSpan(text: auth.displayName, style: AppTypography.serif(size: 30, color: c.textPrimary)),
                    ]),
                  ),
                ],
              )),
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
  const _NetWorthCard({required this.controller, required this.hidden, required this.onToggle});
  final DashboardController controller;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const ink = Color(0xFF17272B);
    const cream = AppColors.cream;
    final muted = cream.withValues(alpha: 0.68);
    final m = controller;
    final flow = m.monthIncome.value - m.monthExpense.value;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? c.surfaceRaised : ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Kekayaan bersih', style: TextStyle(color: muted, fontSize: 14)),
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
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedMoney(
              value: m.netWorth.value,
              hidden: hidden,
              style: AppTypography.display(size: 48, weight: FontWeight.w500, color: cream),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 28,
            runSpacing: 12,
            children: [
              _Figure(label: 'Aset', value: m.totalAssets.value, hidden: hidden, color: cream, muted: muted),
              _Figure(label: 'Liabilitas', value: m.totalLiabilities.value.abs(), hidden: hidden, color: cream, muted: muted),
              _Figure(label: 'Masuk bulan ini', value: m.monthIncome.value, hidden: hidden, color: cream, muted: muted),
              _Figure(label: 'Keluar bulan ini', value: m.monthExpense.value, hidden: hidden, color: cream, muted: muted),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: cream.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(flow >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 18, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hidden
                      ? 'Arus kas bulan ini disembunyikan'
                      : (flow >= 0 ? 'Bulan ini Anda surplus ${flow.rupiah}' : 'Bulan ini Anda defisit ${(-flow).rupiah}'),
                  style: TextStyle(color: cream, fontSize: 13.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, required this.hidden, required this.color, required this.muted});
  final String label;
  final int value;
  final bool hidden;
  final Color color;
  final Color muted;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 2),
          AnimatedMoney(value: value, hidden: hidden, style: AppTypography.numeric(size: 15, weight: FontWeight.w600, color: color)),
        ],
      );
}

/// The smart report's lead sentence, surfaced where it will be read. In the
/// first week of a month it switches to last month's closing report.
class _InsightTeaser extends StatelessWidget {
  const _InsightTeaser();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final closing = now.day <= 7;
    final month = closing ? DateTime(now.year, now.month - 1) : DateTime(now.year, now.month);
    final r = SmartReportService().forMonth(month);
    final notes = [...r.narrative.where((n) => n.tone == InsightTone.warning), ...r.narrative.where((n) => n.tone != InsightTone.warning)];

    return Pressable(
      onTap: () => Get.find<ShellController>().goTo(AppPage.reports),
      semanticLabel: 'Buka laporan',
      borderRadius: BorderRadius.circular(16),
      builder: (context, s, _) => AnimatedContainer(
        duration: AppMotion.hover,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: s.active ? c.textPrimary.withValues(alpha: 0.4) : c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 18, color: c.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    closing ? 'Laporan ${DateFormat('MMMM', 'id_ID').format(month)} siap' : 'Ringkasan bulan ini',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                AnimatedSlide(
                  offset: Offset(s.active ? 0.2 : 0, 0),
                  duration: AppMotion.hover,
                  child: Icon(Icons.arrow_forward_rounded, size: 18, color: c.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final n in notes.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: n.tone == InsightTone.warning ? c.warning : (n.tone == InsightTone.good ? c.success : c.textTertiary),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(n.text, style: TextStyle(color: c.textSecondary, height: 1.45, fontSize: 14))),
                  ],
                ),
              ),
          ],
        ),
      ),
      child: const SizedBox.shrink(),
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
  const _AccountsSection({required this.controller});
  final DashboardController controller;

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
        // The fanned stack is wider than its column on desktop; keep it inside.
        ClipRect(
          child: AccountCardStack(
            accounts: accounts,
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

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.controller, required this.onSet});
  final DashboardController controller;
  final VoidCallback onSet;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final b = controller.overallBudget.value;
    if (b == null || b.limit <= 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Anggaran bulanan', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Tetapkan batas agar Wallet bisa memberi peringatan dini.', style: TextStyle(color: c.textSecondary, fontSize: 13.5)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              WButton(label: 'Atur', size: WButtonSize.small, variant: WButtonVariant.tonal, onPressed: onSet),
            ],
          ),
        ),
      );
    }
    final color = b.isOver ? c.budgetOver : (b.isNearLimit ? c.budgetWarn : c.textPrimary);
    final left = b.limit - b.spent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Anggaran bulanan', style: Theme.of(context).textTheme.titleMedium)),
                Text('${(b.percent * 100).clamp(0, 999).toStringAsFixed(0)}%',
                    style: AppTypography.numeric(size: 14, weight: FontWeight.w600, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, box) => Stack(
                children: [
                  Container(height: 8, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(4))),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: b.percent.clamp(0, 1).toDouble()),
                    duration: AppMotion.of(context, const Duration(milliseconds: 900)),
                    curve: AppMotion.emphasized,
                    builder: (_, v, _) => Container(
                      width: box.maxWidth * v,
                      height: 8,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              left >= 0 ? 'Sisa ${left.rupiah} dari ${b.limit.rupiah}' : 'Terlampaui ${(-left).rupiah} dari ${b.limit.rupiah}',
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/util/thousands_formatter/thousands_formatter.dart';
import 'package:financial_recording/data/models/goal_model/goal_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/presentation/goals/controller/goals_controller.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/util/money/money_format.dart';

class GoalsView extends StatelessWidget {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(GoalsController());
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Target Finansial & Impian'),
      ),
      // The empty state has its own button; show this one once goals exist.
      floatingActionButton: Obx(() => c.activeGoals.isEmpty && c.completedGoals.isEmpty
          ? const SizedBox.shrink()
          : FloatingActionButton.extended(
              onPressed: () => _showGoalEditor(context, c),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Target'),
            )),
      body: RefreshIndicator(
        onRefresh: () async => c.refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ContentShell(
            child: Obx(() {
              final active = c.activeGoals;
              final completed = c.completedGoals;

              if (active.isEmpty && completed.isEmpty) {
                return _EmptyGoalsState(onAdd: () => _showGoalEditor(context, c));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary Banner
                  _GoalsSummaryBanner(controller: c),
                  const SizedBox(height: AppSpacing.lg),

                  // Active Goals Section
                  if (active.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.flag_rounded, size: 18, color: colors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Target Berjalan (${active.length})',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final goal in active)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _GoalCard(
                          goal: goal,
                          onDeposit: () => _showDepositModal(context, c, goal),
                          onDelete: () => c.deleteGoal(goal.id),
                          onEdit: () => _showGoalEditor(context, c, existing: goal),
                        ),
                      ),
                  ],

                  // Completed Goals Section
                  if (completed.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Icon(Icons.celebration_rounded, size: 18, color: colors.income),
                        const SizedBox(width: 6),
                        Text(
                          'Target Tercapai 🎉 (${completed.length})',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.income,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final goal in completed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _GoalCard(
                          goal: goal,
                          onDeposit: null,
                          onDelete: () => c.deleteGoal(goal.id),
                          onEdit: () => _showGoalEditor(context, c, existing: goal),
                        ),
                      ),
                  ],

                  const SizedBox(height: AppSpacing.xxxl + 20),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  void _showGoalEditor(BuildContext context, GoalsController c, {FinancialGoalModel? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final targetCtrl = TextEditingController(text: existing != null ? formatThousands(existing.targetAmount) : '');
    final currentCtrl = TextEditingController(text: existing != null ? formatThousands(existing.currentAmount) : '0');
    DateTime? selectedDate = existing?.targetDate;
    int selectedColor = existing?.colorValue ?? 0xFF0D9488;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KeyboardInset(child: StatefulBuilder(
        builder: (ctx, setModalState) {
          final colors = ctx.colors;
          return Container(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing == null ? 'Tambah Target Keuangan' : 'Ubah Target',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Target / Impian',
                      hintText: 'Misal: Laptop Baru, Liburan, Dana Darurat',
                      prefixIcon: Icon(Icons.stars_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Target Nominal',
                      prefixText: 'Rp ',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: currentCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Sudah Terkumpul Saat Ini',
                      prefixText: 'Rp ',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_rounded),
                    title: Text(
                      selectedDate == null
                          ? 'Tentukan Target Tanggal (Opsional)'
                          : 'Target: ${DateFormat('d MMMM yyyy', 'id_ID').format(selectedDate!)}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 90)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final targetAmount = int.tryParse(targetCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      final currentAmount = int.tryParse(currentCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

                      if (title.isEmpty || targetAmount <= 0) {
                        Get.snackbar('Perhatian', 'Nama target dan nominal target harus diisi.');
                        return;
                      }

                      await c.saveGoal(
                        id: existing?.id,
                        title: title,
                        targetAmount: targetAmount,
                        currentAmount: currentAmount,
                        targetDate: selectedDate,
                        colorValue: selectedColor,
                      );

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(existing == null ? 'Simpan Target' : 'Perbarui Target'),
                  ),
                ],
              ),
            ),
          );
        },
      )),
    );
  }

  void _showDepositModal(BuildContext context, GoalsController c, FinancialGoalModel goal) {
    final amountCtrl = TextEditingController();
    final accounts = AccountRepository().all();
    String? selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KeyboardInset(child: StatefulBuilder(
        builder: (ctx, setModalState) {
          final colors = ctx.colors;
          return Container(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tabung ke: ${goal.title}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Sisa target yang dibutuhkan: ${goal.remainingAmount.rupiah}',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Nominal Tabungan',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.savings_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (accounts.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Ambil dari Rekening/Dompet',
                      prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                    ),
                    items: [
                      for (final acc in accounts)
                        DropdownMenuItem(
                          value: acc.id,
                          child: Text('${acc.name} (${acc.cachedBalance.rupiah})'),
                        ),
                    ],
                    onChanged: (val) => setModalState(() => selectedAccountId = val),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                FilledButton.icon(
                  onPressed: () async {
                    final amount = int.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    if (amount <= 0) {
                      Get.snackbar('Perhatian', 'Masukkan nominal tabungan yang valid.');
                      return;
                    }
                    await c.addContribution(goal.id, amount, selectedAccountId);
                    if (ctx.mounted) Navigator.pop(ctx);

                    Get.showSnackbar(
                      GetSnackBar(
                        message: '🎉 Berhasil menabung ${amount.rupiah} ke ${goal.title}!',
                        duration: const Duration(seconds: 3),
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(16),
                        borderRadius: 12,
                        backgroundColor: const Color(0xFF0D9488),
                      ),
                    );
                  },
                  icon: const Icon(Icons.savings_rounded),
                  label: const Text('Tabung Sekarang'),
                ),
              ],
            )),
          );
        },
      )),
    );
  }
}

class _GoalsSummaryBanner extends StatelessWidget {
  const _GoalsSummaryBanner({required this.controller});
  final GoalsController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final saved = controller.totalSaved.value;
    final target = controller.totalTarget.value;
    final progress = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            Color.lerp(colors.primary, Colors.black, 0.3)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Tabungan Impian',
                style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.8), fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(progress * 100).round()}% Tercapai',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            saved.rupiah,
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Target keseluruhan: ${target.rupiah}',
            style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.75), fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(colors.onPrimary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onDeposit,
    required this.onDelete,
    required this.onEdit,
  });

  final FinancialGoalModel goal;
  final VoidCallback? onDeposit;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = Color(goal.colorValue);
    final isDone = goal.isCompleted;

    String? daysLeftText;
    if (goal.targetDate != null) {
      final diff = goal.targetDate!.difference(DateTime.now()).inDays;
      if (diff > 0) {
        daysLeftText = 'Sisa $diff hari';
      } else if (diff == 0) {
        daysLeftText = 'Jatuh tempo hari ini';
      } else {
        daysLeftText = 'Terlewat ${-diff} hari';
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone ? colors.income.withValues(alpha: 0.4) : colors.border.withValues(alpha: colors.border.a * 0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDone ? colors.income.withValues(alpha: 0.15) : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDone ? Icons.celebration_rounded : Icons.savings_rounded,
                  color: isDone ? colors.income : color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (daysLeftText != null)
                      Text(
                        daysLeftText,
                        style: TextStyle(fontSize: 11, color: colors.textTertiary),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.currentAmount.rupiah,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDone ? colors.income : colors.textPrimary,
                ),
              ),
              Text(
                '${goal.progressPercent}% / ${goal.targetAmount.rupiah}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: colors.border.withValues(alpha: colors.border.a * 0.4),
              valueColor: AlwaysStoppedAnimation(isDone ? colors.income : color),
              minHeight: 8,
            ),
          ),
          if (onDeposit != null && !isDone) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onDeposit,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text('Tabung Sekarang'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyGoalsState extends StatelessWidget {
  const _EmptyGoalsState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.stars_rounded, size: 44, color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Mulai Rencanakan Impian Finansialmu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat target tabungan seperti Beli Gadget, Dana Darurat, atau Liburan untuk mengukur pencapaian keuangan Anda secara terarah.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat Target Pertama'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/data/services/budget_service_v2.dart';
import 'package:financial_recording/presentation/budgets/controller/budgets_controller.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/adaptive_grid.dart';
import 'package:financial_recording/shared/responsive/breakpoints.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/util/money/money_format.dart';

class BudgetsView extends StatelessWidget {
  const BudgetsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(BudgetsController(), tag: 'budgets');
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Anggaran'),
      ),
      body: SingleChildScrollView(
        child: ContentShell(
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: c.previousMonth),
                      Text(DateFormat('MMMM y', 'id_ID').format(c.month.value), style: Theme.of(context).textTheme.titleMedium),
                      IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: c.nextMonth),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _BudgetCard(
                    title: 'Anggaran total bulan ini',
                    progress: c.overall.value,
                    onTap: () => _editBudget(context, initial: c.overall.value?.limit ?? 0, onSave: c.setOverallBudget),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Per kategori', style: Theme.of(context).textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: () => _pickCategoryThenBudget(context, c),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Tambah'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (c.categoryProgress.isEmpty)
                    Text('Belum ada anggaran per kategori.', style: TextStyle(color: colors.textSecondary))
                  else
                    AdaptiveGrid(
                      columnsOverride: context.isCompact ? 1 : 2,
                      children: [
                        for (final p in c.categoryProgress)
                          _BudgetCard(
                            title: c.categories.pathName(p.categoryId ?? ''),
                            progress: p,
                            onTap: () => _editBudget(
                              context,
                              initial: p.limit,
                              onSave: (amount) => c.setCategoryBudget(p.categoryId!, amount),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              )),
        ),
      ),
    );
  }

  Future<void> _pickCategoryThenBudget(BuildContext context, BudgetsController c) async {
    final roots = c.categories.roots(1);
    final selected = await showAdaptiveSheet<String>(
      context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final root in roots) ...[
              ListTile(
                title: Text(root.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Termasuk semua sub-kategori'),
                onTap: () => Navigator.of(sheetContext).pop(root.id),
              ),
              for (final child in c.categories.childrenOf(root.id))
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 32),
                  title: Text(child.name),
                  onTap: () => Navigator.of(sheetContext).pop(child.id),
                ),
            ],
          ],
        ),
      ),
    );
    if (selected != null && context.mounted) {
      await _editBudget(context, initial: 0, onSave: (amount) => c.setCategoryBudget(selected, amount));
    }
  }

  Future<void> _editBudget(BuildContext context, {required int initial, required Future<void> Function(int) onSave}) async {
    final controller = TextEditingController(text: initial == 0 ? '' : initial.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jumlah anggaran'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: 'Rp '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(int.tryParse(controller.text) ?? 0),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) await onSave(result);
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.title, required this.progress, required this.onTap});
  final String title;
  final BudgetProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final p = progress;
    final color = p == null || !p.isOver && !p.isNearLimit
        ? colors.budgetSafe
        : (p.isOver ? colors.budgetOver : colors.budgetWarn);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: p == null || p.limit == 0 ? 0 : p.percent.clamp(0, 1).toDouble(),
                  minHeight: 8,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                p == null || p.limit == 0
                    ? 'Belum diatur — ketuk untuk mengatur'
                    : '${p.spent.rupiah} dari ${p.limit.rupiah}',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

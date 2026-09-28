import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/shared/widget/art_icon.dart';
import 'package:financial_recording/presentation/recurring/controller/recurring_controller.dart';
import 'package:financial_recording/presentation/recurring/widget/recurring_editor_sheet.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/widget/empty_state.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/util/money/money_format.dart';

class RecurringView extends StatelessWidget {
  const RecurringView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RecurringController(), tag: 'recurring');
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // "Tambah" lives in the app bar: a page FAB stacked right above the
      // shell's own "+" looked like two identical buttons.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Transaksi Berulang'),
        actions: [
          Obx(() => c.rules.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: FilledButton.icon(
                    onPressed: () => _add(context, c),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah'),
                  ),
                )),
        ],
      ),
      body: SingleChildScrollView(
        child: ContentShell(
          child: Obx(() {
            if (c.rules.isEmpty) {
              return EmptyState(
                icon: Icons.event_repeat_rounded,
                title: 'Belum ada transaksi berulang',
                body: 'Gaji, cicilan, SPP, dan langganan bisa tercatat sendiri setiap jatuh tempo.',
                actionLabel: 'Tambah transaksi berulang',
                onAction: () => _add(context, c),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in c.rules)
                  Dismissible(
                    key: ValueKey(r.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(color: colors.danger, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    ),
                    confirmDismiss: (_) => showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus aturan berulang?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
                          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
                        ],
                      ),
                    ),
                    onDismissed: (_) => c.delete(r.id),
                    child: _RuleCard(
                      rule: r,
                      onTap: () async {
                        final result = await showAdaptiveSheet<RecurringRuleModel>(
                          context,
                          builder: (_) => RecurringEditorSheet(existing: r),
                        );
                        if (result != null) await c.save(result);
                      },
                      onToggle: () => c.toggleActive(r),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, RecurringController c) async {
    final result = await showAdaptiveSheet<RecurringRuleModel>(context, builder: (_) => const RecurringEditorSheet());
    if (result != null) await c.save(result);
  }
}

/// One rule: what it is (category or transfer route), how often, from which
/// account, when it runs next — and the signed amount in the type's colour.
class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.onTap, required this.onToggle});
  final RecurringRuleModel rule;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  static const _freqLabel = {
    RecurrenceFreq.daily: 'Harian',
    RecurrenceFreq.weekly: 'Mingguan',
    RecurrenceFreq.monthly: 'Bulanan',
    RecurrenceFreq.yearly: 'Tahunan',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final r = rule;
    final accounts = AccountRepository();
    final category = r.categoryId == null ? null : TxCategoryRepository().byId(r.categoryId!);
    final from = accounts.byId(r.accountId)?.name ?? '-';
    final to = r.toAccountId == null ? null : accounts.byId(r.toAccountId!)?.name;

    final (typeColor, typeLabel, sign, fallbackIcon) = switch (r.type) {
      TxType.income => (colors.income, 'Pemasukan', '+', Icons.south_west_rounded),
      TxType.expense => (colors.expense, 'Pengeluaran', '-', Icons.north_east_rounded),
      TxType.transfer => (colors.transfer, 'Transfer', '', Icons.swap_horiz_rounded),
    };
    final title = r.memo?.isNotEmpty == true
        ? r.memo!
        : r.type == TxType.transfer
            ? 'Transfer ke ${to ?? '-'}'
            : category?.name ?? typeLabel;
    final route = r.type == TxType.transfer ? '$from → ${to ?? '-'}' : from;
    final baseColor = category != null ? Color(category.colorValue) : typeColor;
    final hasEmoji = category?.emoji?.isNotEmpty == true;

    return Opacity(
      opacity: r.isActive ? 1 : 0.55,
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
            child: Row(
              children: [
                ArtIcon(
                  size: 44,
                  backgroundColor: baseColor.withValues(alpha: 0.14),
                  borderColor: baseColor.withValues(alpha: 0.25),
                  emoji: category?.emoji,
                  iconColor: baseColor,
                  child: hasEmoji ? null : Icon(fallbackIcon, color: typeColor, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        '${_freqLabel[r.freq]} · $route',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                      ),
                      Text(
                        r.isActive ? 'Berikutnya ${DateFormat('d MMM y', 'id_ID').format(r.nextRunDate)}' : 'Dijeda',
                        style: TextStyle(fontSize: 12, color: colors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$sign${r.amount.rupiah}', style: TextStyle(fontWeight: FontWeight.w700, color: typeColor)),
                    Transform.scale(
                      scale: 0.8,
                      alignment: Alignment.centerRight,
                      child: Switch(value: r.isActive, onChanged: (_) => onToggle()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

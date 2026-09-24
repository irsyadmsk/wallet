import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
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
    final accounts = AccountRepository();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Transaksi Berulang')),
      floatingActionButton: Obx(
        () => c.rules.isEmpty
            ? const SizedBox.shrink()
            : FloatingActionButton(
                tooltip: 'Tambah transaksi berulang',
                onPressed: () => _add(context, c),
                child: const Icon(Icons.add_rounded),
              ),
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
                    child: Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        onTap: () async {
                          final result = await showAdaptiveSheet<RecurringRuleModel>(
                            context,
                            builder: (_) => RecurringEditorSheet(existing: r),
                          );
                          if (result != null) await c.save(result);
                        },
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.border.withValues(alpha: colors.border.a * 0.5), width: 1),
                          ),
                          child: Icon(Icons.autorenew_rounded, color: colors.primary, size: 22),
                        ),
                        title: Text(
                          r.memo?.isNotEmpty == true ? r.memo! : (accounts.byId(r.accountId)?.name ?? 'Berulang'),
                        ),
                        subtitle: Text('Berikutnya: ${DateFormat('d MMM y', 'id_ID').format(r.nextRunDate)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(r.amount.rupiah, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Switch(value: r.isActive, onChanged: (_) => c.toggleActive(r)),
                          ],
                        ),
                      ),
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

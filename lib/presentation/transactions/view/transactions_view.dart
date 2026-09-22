import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/presentation/form_tx/view/form_tx_view.dart';
import 'package:financial_recording/presentation/transactions/controller/transactions_controller.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/tx_tile.dart';
import 'package:financial_recording/util/money/money_format.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(TransactionsController(), tag: 'transactions');
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Transaksi'),
        actions: [
          Obx(() => IconButton(
                tooltip: 'Ekspor CSV (Excel)',
                icon: c.exporting.value
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.table_chart_rounded),
                onPressed: c.exporting.value
                    ? null
                    : () async {
                        final ok = await c.exportVisibleToCsv();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok ? 'Ekspor berhasil.' : 'Ekspor dibatalkan.')),
                          );
                        }
                      },
              )),
        ],
      ),
      body: SingleChildScrollView(
        child: ContentShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari catatan atau item...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: c.setSearch,
              ),
              const SizedBox(height: AppSpacing.sm),
              Obx(() => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Semua',
                          selected: c.typeFilter.value == null && !c.onlyWithReceipt.value,
                          onTap: () {
                            if (c.onlyWithReceipt.value) c.toggleOnlyWithReceipt();
                            c.setTypeFilter(null);
                          },
                        ),
                        _FilterChip(
                          label: 'Pemasukan',
                          selected: c.typeFilter.value?.contains(TxType.income) == true,
                          onTap: () => c.setTypeFilter({TxType.income}),
                        ),
                        _FilterChip(
                          label: 'Pengeluaran',
                          selected: c.typeFilter.value?.contains(TxType.expense) == true,
                          onTap: () => c.setTypeFilter({TxType.expense}),
                        ),
                        _FilterChip(
                          label: 'Transfer',
                          selected: c.typeFilter.value?.contains(TxType.transfer) == true,
                          onTap: () => c.setTypeFilter({TxType.transfer}),
                        ),
                        _FilterChip(
                          label: '🧾 Ada Struk',
                          selected: c.onlyWithReceipt.value,
                          onTap: c.toggleOnlyWithReceipt,
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: AppSpacing.sm),
              Obx(() => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Text('Kelompokkan:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                        ),
                        for (final mode in TxGroupMode.values)
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: ChoiceChip(
                              label: Text(mode.label),
                              selected: c.groupMode.value == mode,
                              onSelected: (_) => c.setGroupMode(mode),
                            ),
                          ),
                      ],
                    ),
                  )),
              const SizedBox(height: AppSpacing.md),
              Obx(() {
                final groups = c.groups;
                if (groups.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: Text('Tidak ada transaksi.')),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final group in groups) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.label,
                                style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ),
                            Text(
                              'Total ${group.net.signedRupiah}',
                              style: TextStyle(
                                color: group.net >= 0 ? colors.income : colors.expense,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Card(
                        child: Column(
                          children: [
                            for (final tx in group.items)
                              TxTile(
                                tx: tx,
                                showAccount: c.groupMode.value != TxGroupMode.account,
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
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              }),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/presentation/form_tx/view/form_tx_view.dart';
import 'package:financial_recording/presentation/transactions/controller/transactions_controller.dart';
import 'package:financial_recording/presentation/transactions/widget/tx_calendar_view.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/widget/section_card.dart';
import 'package:financial_recording/shared/responsive/breakpoints.dart';
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
                tooltip: c.calendarMode.value ? 'Tampilan daftar' : 'Tampilan kalender',
                icon: Icon(c.calendarMode.value ? Icons.view_list_rounded : Icons.calendar_month_rounded),
                onPressed: c.toggleCalendarMode,
              )),
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
      // Built lazily: a ledger of thousands of rows used to be laid out in
      // one Column, which made this screen (and every refresh) very slow.
      body: LayoutBuilder(builder: (context, constraints) {
        final pad = context.pagePadding;
        final maxW = context.contentMaxWidth;
        final side = constraints.maxWidth > maxW ? (constraints.maxWidth - maxW) / 2 : 0.0;
        final hPad = EdgeInsets.only(left: side + pad.left, right: side + pad.right);
        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: hPad.copyWith(top: pad.top),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cari catatan atau item…',
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
                    Obx(() => c.calendarMode.value
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: SectionCard(child: TxCalendarView(controller: c)),
                          )
                        : const SizedBox.shrink()),
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
                  ],
                ),
              ),
            ),
            Obx(() {
              final rows = c.rows;
              if (rows.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: Text('Tidak ada transaksi.')),
                  ),
                );
              }
              final showAccount = c.groupMode.value != TxGroupMode.account;
              return SliverPadding(
                padding: hPad.copyWith(bottom: pad.bottom),
                sliver: SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    final group = row.group;
                    if (group != null) {
                      return Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.md, bottom: AppSpacing.sm),
                        child: _GroupHeader(group: group),
                      );
                    }
                    final tx = row.tx!;
                    return _CardSegment(
                      isFirst: row.isFirst,
                      isLast: row.isLast,
                      child: _SwipeTx(
                        tx: tx,
                        onChanged: c.refresh,
                        child: TxTile(
                        tx: tx,
                        showAccount: showAccount,
                        onTap: () async {
                          final saved = await showAdaptiveSheet<bool>(
                            context,
                            builder: (_) => FormTxView(existing: tx),
                          );
                          if (saved == true) c.refresh();
                        },
                      ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        );
      }),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});
  final TxGroup group;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
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
    );
  }
}

/// One row of a group's card, drawn per row so the list can stay lazy:
/// the first and last rows carry the card's rounded corners, and the side
/// borders line up into one continuous card.
class _CardSegment extends StatelessWidget {
  const _CardSegment({required this.isFirst, required this.isLast, required this.child});
  final bool isFirst;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const r = Radius.circular(AppRadii.lg);
    final side = BorderSide(color: colors.border, width: 1);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: isFirst ? r : Radius.zero, bottom: isLast ? r : Radius.zero),
        border: Border(
          left: side,
          right: side,
          top: isFirst ? side : BorderSide.none,
          bottom: isLast ? side : BorderSide.none,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: isFirst ? r : Radius.zero, bottom: isLast ? r : Radius.zero),
        child: child,
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

/// Thumb-friendly row actions: swipe left to delete (after a confirm),
/// swipe right to record the same transaction again today.
class _SwipeTx extends StatelessWidget {
  const _SwipeTx({required this.tx, required this.child, required this.onChanged});
  final TxModel tx;
  final Widget child;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget bg(Color color, IconData icon, String label, Alignment align) => Container(
          color: color.withValues(alpha: 0.14),
          alignment: align,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        );
    return Dismissible(
      key: ValueKey('swipe-${tx.id}'),
      background: bg(colors.primary, Icons.replay_rounded, 'Catat lagi', Alignment.centerLeft),
      secondaryBackground: bg(colors.danger, Icons.delete_outline_rounded, 'Hapus', Alignment.centerRight),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          final saved = await showAdaptiveSheet<bool>(
            context,
            builder: (_) => FormTxView(
              initialType: tx.type,
              initialAccountId: tx.accountId,
              initialToAccountId: tx.toAccountId,
              initialCategoryId: tx.categoryId,
              initialMemo: tx.memo,
              initialAmount: tx.amount,
            ),
          );
          if (saved == true) onChanged();
          return false; // the original row stays
        }
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus transaksi ini?'),
            content: const Text('Saldo akun terkait akan disesuaikan kembali.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ctx.colors.danger),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
        if (ok != true) return false;
        await LedgerService().delete(tx.id);
        return true;
      },
      onDismissed: (_) => onChanged(),
      child: child,
    );
  }
}

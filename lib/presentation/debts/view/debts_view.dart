import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:financial_recording/data/models/debt_model/debt_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/presentation/debts/controller/debts_controller.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/art_icon.dart';
import 'package:financial_recording/util/money/money_format.dart';

class DebtsView extends StatelessWidget {
  const DebtsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DebtsController(), tag: 'debts');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Utang & Piutang'),
      ),
      // One add action per screen: the empty state carries its own button,
      // so the floating one only appears once there is a list.
      floatingActionButton: Obx(() => c.filteredList.isEmpty
          ? const SizedBox.shrink()
          : FloatingActionButton.extended(
              onPressed: () => _openFormDialog(context, c),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Catat Pinjaman'),
            )),
      body: Obx(() {
        final list = c.filteredList;
        return ContentShell(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              // Summary Banner
              _buildSummaryBanner(context, c),
              const SizedBox(height: AppSpacing.md),

              // Filter Chips
              _buildFilterChips(context, c),
              const SizedBox(height: AppSpacing.md),

              if (list.isEmpty)
                _buildEmptyState(context, c)
              else
                ...list.map((debt) => _buildDebtCard(context, c, debt)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryBanner(BuildContext context, DebtsController c) {
    final colors = context.colors;
    final totalDebt = c.totalDebt.value;
    final totalLoan = c.totalLoan.value;
    final net = c.netBalance;

    return Card(
      elevation: 0,
      color: colors.surfaceRaised.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border.withValues(alpha: colors.border.a * 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.expense,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Saya Berutang',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totalDebt.rupiah,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: colors.border.withValues(alpha: colors.border.a * 0.5),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors.income,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Piutang Saya',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          totalLoan.rupiah,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.income,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo Bersih Pinjaman',
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                ),
                Text(
                  net >= 0 ? '+${net.rupiah}' : '-${(-net).rupiah}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: net >= 0 ? colors.income : colors.expense,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, DebtsController c) {
    final colors = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DebtFilter.values.map((f) {
          final isSelected = c.filter.value == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.label),
              selected: isSelected,
              onSelected: (_) => c.filter.value = f,
              selectedColor: colors.primaryContainer,
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, DebtsController c, DebtLoanModel debt) {
    final colors = context.colors;
    final isLoan = debt.isLoan;
    final color = isLoan ? colors.income : colors.expense;
    final isSettled = debt.isSettled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSettled
              ? colors.border.withValues(alpha: colors.border.a * 0.3)
              : color.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Avatar, Name, Type Badge, Menu
            Row(
              children: [
                ArtIcon(
                  size: 42,
                  icon: isLoan ? Icons.call_made_rounded : Icons.call_received_rounded,
                  iconColor: isSettled ? colors.textTertiary : color,
                  backgroundColor: (isSettled ? colors.border : color).withValues(alpha: 0.12),
                  borderColor: (isSettled ? colors.border : color).withValues(alpha: 0.25),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            debt.personName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSettled ? colors.textSecondary : colors.textPrimary,
                              decoration: isSettled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isLoan ? colors.income : colors.expense).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isLoan ? 'Piutang' : 'Utang',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isLoan ? colors.income : colors.expense,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDueDate(debt),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: debt.isOverdue
                              ? colors.danger
                              : isSettled
                                  ? colors.success
                                  : colors.textSecondary,
                          fontWeight: debt.isOverdue || isSettled
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 20, color: colors.textSecondary),
                  onSelected: (action) {
                    if (action == 'edit') {
                      _openFormDialog(context, c, existing: debt);
                    } else if (action == 'delete') {
                      _confirmDelete(context, c, debt);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),

            if (debt.notes != null && debt.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                debt.notes!,
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
            ],

            const SizedBox(height: 12),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: debt.progress,
                minHeight: 6,
                backgroundColor: colors.surfaceAlt,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isSettled ? colors.success : color,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Amounts Row & Pay Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sisa: ${debt.remainingAmount.rupiah}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isSettled ? colors.success : color,
                      ),
                    ),
                    Text(
                      'dari total ${debt.totalAmount.rupiah} (${debt.progressPercent}% terbayar)',
                      style: TextStyle(fontSize: 11, color: colors.textTertiary),
                    ),
                  ],
                ),
                if (!isSettled)
                  FilledButton.tonalIcon(
                    onPressed: () => _openPaymentDialog(context, c, debt),
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('Bayar / Cicil'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: colors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Lunas',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: colors.success,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDueDate(DebtLoanModel debt) {
    if (debt.isSettled) return 'Lunas sepenuhnya';
    if (debt.dueDate == null) return 'Tanpa tenggat waktu';
    final fmt = DateFormat('d MMMM yyyy', 'id_ID').format(debt.dueDate!);
    if (debt.isOverdue) {
      final days = DateTime.now().difference(debt.dueDate!).inDays;
      return 'Lewat tempo $days hari ($fmt)';
    }
    final left = debt.dueDate!.difference(DateTime.now()).inDays;
    if (left == 0) return 'Jatuh tempo hari ini!';
    if (left < 7) return 'Jatuh tempo $left hari lagi ($fmt)';
    return 'Jatuh tempo: $fmt';
  }

  Widget _buildEmptyState(BuildContext context, DebtsController c) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            ArtIcon(
              size: 64,
              icon: Icons.assignment_outlined,
              backgroundColor: colors.surfaceAlt,
              borderColor: colors.border,
              iconColor: colors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada catatan utang & piutang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Catat pinjaman dengan teman, keluarga, atau tagihan kredit',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _openFormDialog(context, c),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Pinjaman'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFormDialog(
    BuildContext context,
    DebtsController c, {
    DebtLoanModel? existing,
  }) async {
    final colors = context.colors;
    final isEdit = existing != null;
    bool isLoan = existing?.isLoan ?? false;
    final nameCtrl = TextEditingController(text: existing?.personName ?? '');
    final amountCtrl = TextEditingController(
      text: existing != null ? existing.totalAmount.toString() : '',
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    DateTime? dueDate = existing?.dueDate;
    bool syncWallet = false;
    final accounts = AccountRepository().all();
    String? selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;

    await showAdaptiveSheet<void>(
      context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit Catatan Pinjaman' : 'Catat Pinjaman Baru',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),

              // Segmented Button: Utang vs Piutang
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Saya Berutang'),
                    icon: Icon(Icons.call_received_rounded),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Piutang Saya'),
                    icon: Icon(Icons.call_made_rounded),
                  ),
                ],
                selected: {isLoan},
                onSelectionChanged: (set) => setState(() => isLoan = set.first),
              ),
              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: isLoan ? 'Nama Peminjam' : 'Nama Pemberi Pinjaman',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal Total Pinjaman',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.money_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded),
                title: Text(
                  dueDate == null
                      ? 'Pilih Jatuh Tempo (Opsional)'
                      : 'Jatuh Tempo: ${DateFormat('d MMMM yyyy', 'id_ID').format(dueDate!)}',
                ),
                trailing: dueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => dueDate = null),
                      )
                    : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
              ),

              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              if (!isEdit && accounts.isNotEmpty) ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: syncWallet,
                  onChanged: (v) => setState(() => syncWallet = v ?? false),
                  title: const Text('Sinkronkan dengan Saldo Dompet'),
                  subtitle: Text(
                    isLoan
                        ? 'Otomatis catat pengeluaran dari dompet'
                        : 'Otomatis catat pemasukan pinjaman ke dompet',
                    style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                  ),
                ),
                if (syncWallet)
                  DropdownButtonFormField<String>(
                    initialValue: selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Dompet / Rekening',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: accounts
                        .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedAccountId = val),
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],

              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final rawAmt = amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                  final amount = int.tryParse(rawAmt) ?? 0;
                  if (name.isEmpty || amount <= 0) return;

                  final model = existing ??
                      DebtLoanModel(
                        id: const Uuid().v4(),
                        isLoan: isLoan,
                        personName: name,
                        totalAmount: amount,
                        dueDate: dueDate,
                        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      );

                  if (isEdit) {
                    model.personName = name;
                    model.isLoan = isLoan;
                    model.dueDate = dueDate;
                    model.notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
                  }

                  await c.saveDebt(
                    model,
                    accountId: syncWallet ? selectedAccountId : null,
                    syncWallet: syncWallet,
                  );
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
                child: Text(isEdit ? 'Simpan Perubahan' : 'Catat Pinjaman'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPaymentDialog(
    BuildContext context,
    DebtsController c,
    DebtLoanModel debt,
  ) async {
    final colors = context.colors;
    final payCtrl = TextEditingController(text: debt.remainingAmount.toString());
    final notesCtrl = TextEditingController();
    bool syncWallet = true;
    final accounts = AccountRepository().all();
    String? selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;

    await showAdaptiveSheet<void>(
      context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                debt.isLoan ? 'Terima Pembayaran Piutang' : 'Bayar Cicilan Utang',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Pihak: ${debt.personName} · Sisa: ${debt.remainingAmount.rupiah}',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: payCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nominal Pembayaran',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan Pembayaran (Opsional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              if (accounts.isNotEmpty) ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: syncWallet,
                  onChanged: (v) => setState(() => syncWallet = v ?? false),
                  title: const Text('Sinkronkan dengan Saldo Dompet'),
                  subtitle: Text(
                    debt.isLoan
                        ? 'Catat uang masuk ke dompet yang dipilih'
                        : 'Catat pengeluaran kas dari dompet yang dipilih',
                    style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                  ),
                ),
                if (syncWallet)
                  DropdownButtonFormField<String>(
                    value: selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Dompet / Rekening',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: accounts
                        .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedAccountId = val),
                  ),
              ],

              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  final rawAmt = payCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                  final amount = int.tryParse(rawAmt) ?? 0;
                  if (amount <= 0) return;

                  await c.recordPayment(
                    debt.id,
                    amount,
                    accountId: syncWallet ? selectedAccountId : null,
                    syncWallet: syncWallet,
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  );
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Simpan Pembayaran'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DebtsController c, DebtLoanModel debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text('Hapus catatan pinjaman dengan "${debt.personName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.danger),
            onPressed: () {
              c.deleteDebt(debt.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

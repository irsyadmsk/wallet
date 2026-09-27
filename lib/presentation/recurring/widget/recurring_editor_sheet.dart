import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:financial_recording/shared/widget/form/amount_field.dart';
import 'package:financial_recording/core.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';

class RecurringEditorSheet extends StatefulWidget {
  const RecurringEditorSheet({super.key, this.existing});
  final RecurringRuleModel? existing;

  @override
  State<RecurringEditorSheet> createState() => _RecurringEditorSheetState();
}

class _RecurringEditorSheetState extends State<RecurringEditorSheet> {
  final _accounts = AccountRepository();
  final _categories = TxCategoryRepository();

  late TxType type = widget.existing?.type ?? TxType.expense;
  late String? accountId = widget.existing?.accountId ?? _accounts.all().firstOrNull?.id;
  late String? toAccountId = widget.existing?.toAccountId;
  late String? categoryId = widget.existing?.categoryId;
  late int amount = widget.existing?.amount ?? 0;
  late RecurrenceFreq freq = widget.existing?.freq ?? RecurrenceFreq.monthly;
  late DateTime startDate = widget.existing?.startDate ?? DateTime.now();
  late bool autoPost = widget.existing?.autoPost ?? true;
  late String memo = widget.existing?.memo ?? '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing != null ? 'Ubah aturan berulang' : 'Aturan berulang baru',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            QDropdownField(
              label: 'Jenis',
              value: type.name,
              items: const [
                {'value': 'expense', 'label': 'Pengeluaran'},
                {'value': 'income', 'label': 'Pemasukan'},
                {'value': 'transfer', 'label': 'Transfer'},
              ],
              onChanged: (v, _) => setState(() {
                final next = TxType.values.firstWhere((t) => t.name == v, orElse: () => type);
                // Expense and income have separate category lists.
                if (next != type) categoryId = null;
                type = next;
              }),
            ),
            AmountField(
              label: 'Jumlah',
              value: amount,
              onChanged: (v) => amount = v,
            ),
            QDropdownField(
              label: type == TxType.transfer ? 'Dari akun' : 'Akun',
              value: accountId,
              items: [for (final a in _accounts.all()) {'value': a.id, 'label': a.name}],
              onChanged: (v, _) => setState(() => accountId = v as String?),
            ),
            if (type == TxType.transfer)
              QDropdownField(
                label: 'Ke akun',
                value: toAccountId,
                items: [for (final a in _accounts.all()) {'value': a.id, 'label': a.name}],
                onChanged: (v, _) => setState(() => toAccountId = v as String?),
              )
            else
              QDropdownField(
                label: 'Kategori',
                value: categoryId,
                items: [
                  for (final cat in _categories.byType(type == TxType.income ? 0 : 1))
                    {'value': cat.id, 'label': cat.displayName}
                ],
                onChanged: (v, _) => setState(() => categoryId = v as String?),
              ),
            QDropdownField(
              label: 'Frekuensi',
              value: freq.name,
              items: const [
                {'value': 'daily', 'label': 'Harian'},
                {'value': 'weekly', 'label': 'Mingguan'},
                {'value': 'monthly', 'label': 'Bulanan'},
                {'value': 'yearly', 'label': 'Tahunan'},
              ],
              onChanged: (v, _) => setState(() => freq = RecurrenceFreq.values.firstWhere((f) => f.name == v)),
            ),
            QDatePicker(label: 'Mulai', value: startDate, onChanged: (v) => startDate = v),
            Row(
              children: [
                Switch(value: autoPost, onChanged: (v) => setState(() => autoPost = v)),
                const Expanded(child: Text('Catat otomatis saat jatuh tempo')),
              ],
            ),
            QMemoField(label: 'Catatan', value: memo, onChanged: (v) => memo = v, maxLines: 2),
            const SizedBox(height: AppSpacing.lg),
            QButton(
              label: 'Simpan',
              onPressed: () {
                if (accountId == null || amount <= 0) return;
                final rule = widget.existing ??
                    RecurringRuleModel(
                      id: const Uuid().v4(),
                      type: type,
                      amount: amount,
                      accountId: accountId!,
                      startDate: startDate,
                    );
                rule
                  ..type = type
                  ..amount = amount
                  ..accountId = accountId!
                  ..toAccountId = type == TxType.transfer ? toAccountId : null
                  ..categoryId = type == TxType.transfer ? null : categoryId
                  ..freq = freq
                  ..startDate = startDate
                  ..nextRunDate = widget.existing?.nextRunDate ?? startDate
                  ..autoPost = autoPost
                  ..memo = memo.trim().isEmpty ? null : memo.trim();
                Navigator.of(context).pop(rule);
              },
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

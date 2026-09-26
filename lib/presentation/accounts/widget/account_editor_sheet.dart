import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:financial_recording/shared/widget/form/amount_field.dart';
import 'package:financial_recording/core.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/repositories/account_group_repository.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/bank_logo_picker.dart';

class AccountEditorSheet extends StatefulWidget {
  const AccountEditorSheet({super.key, this.existing});

  final AccountModel? existing;

  @override
  State<AccountEditorSheet> createState() => _AccountEditorSheetState();
}

class _AccountEditorSheetState extends State<AccountEditorSheet> {
  late String name = widget.existing?.name ?? '';
  final _groups = AccountGroupRepository();
  late AccountGroup group = _groups.of(widget.existing?.groupCode ?? AccountGroupType.cash.code);
  late int openingBalance = widget.existing?.openingBalance ?? 0;
  late bool isLiability = widget.existing?.isLiability ?? group.isLiabilityDefault;
  late int colorValue = widget.existing?.colorValue ?? 0xFF4F46E5;
  late String? iconPath = widget.existing?.iconPath;
  late int? dueDay = widget.existing?.dueDay;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEditing = widget.existing != null;

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
            Text(
              isEditing ? 'Ubah akun' : 'Tambah akun',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            QTextField(
              label: 'Nama akun',
              value: name,
              onChanged: (v) => name = v,
            ),
            QDropdownField(
              label: 'Kelompok akun',
              value: group.code,
              items: [
                for (final g in _groups.all())
                  if (!g.hidden || g.code == group.code) {'value': g.code, 'label': '${g.icon} ${g.label}'}
              ],
              onChanged: (value, _) {
                setState(() {
                  final g = _groups.of(value as int? ?? group.code);
                  group = g;
                  if (!isEditing) isLiability = g.isLiabilityDefault;
                });
              },
            ),
            AmountField(
              label: isEditing ? 'Saldo awal' : 'Saldo saat ini',
              value: openingBalance,
              allowNegative: true,
              showQuickChips: false,
              helper: isLiability ? 'Utang ditulis minus, mis. -1.500.000' : null,
              onChanged: (v) => openingBalance = v,
            ),
            Row(
              children: [
                Checkbox(
                  value: isLiability,
                  onChanged: (v) => setState(() => isLiability = v ?? false),
                ),
                const Expanded(child: Text('Perlakukan sebagai utang / liabilitas')),
              ],
            ),
            if (isLiability)
              QDropdownField(
                label: 'Tanggal jatuh tempo (opsional)',
                value: dueDay,
                items: [
                  for (var d = 1; d <= 31; d++) {'value': d, 'label': 'Tanggal $d setiap bulan'}
                ],
                onChanged: (v, _) => setState(() => dueDay = v as int?),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text('Logo bank / dompet digital', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            BankLogoPicker(
              selected: iconPath,
              onSelected: (v) => setState(() => iconPath = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Warna', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in _palette)
                  GestureDetector(
                    onTap: () => setState(() => colorValue = c),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(c),
                      child: colorValue == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                if (isEditing)
                  Expanded(
                    child: QOutlineButton(
                      label: 'Hapus',
                      color: colors.danger,
                      onPressed: () async {
                        if (!await confirmDeleteAccount(context, widget.existing!)) return;
                        if (context.mounted) {
                          Navigator.of(context).pop<_AccountEditorResult>(_AccountEditorResult.delete(widget.existing!.id));
                        }
                      },
                    ),
                  ),
                if (isEditing) const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: QButton(
                    label: 'Simpan',
                    onPressed: () {
                      if (name.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nama akun tidak boleh kosong')),
                        );
                        return;
                      }
                      final account = widget.existing ??
                          AccountModel(id: const Uuid().v4(), name: name, groupCode: group.code);
                      account
                        ..name = name.trim()
                        ..groupCode = group.code
                        ..isLiability = isLiability
                        ..colorValue = colorValue
                        ..iconPath = iconPath
                        ..dueDay = isLiability ? dueDay : null;
                      if (isEditing) {
                        // Opening balance used to be shown here but silently
                        // ignored on save. Shift the cached balance by the
                        // same delta so the ledger stays consistent.
                        account.cachedBalance += openingBalance - account.openingBalance;
                        account.openingBalance = openingBalance;
                      } else {
                        account.openingBalance = openingBalance;
                        account.cachedBalance = openingBalance;
                      }
                      Navigator.of(context).pop<_AccountEditorResult>(_AccountEditorResult.save(account));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _palette = [
  0xFF4F46E5,
  0xFF0EA5E9,
  0xFF10B981,
  0xFFF59E0B,
  0xFFEF4444,
  0xFF8B5CF6,
  0xFFEC4899,
  0xFF64748B,
];

/// Asks before soft-deleting [account]. Its transactions stay, and the
/// account can be restored from Pengaturan > Akun Terhapus.
Future<bool> confirmDeleteAccount(BuildContext context, AccountModel account) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Hapus akun "${account.name}"?'),
      content: const Text(
        'Akun disembunyikan dari daftar dan saldo total. Riwayat transaksinya tetap tersimpan, '
        'dan akun bisa dipulihkan dari Pengaturan › Akun Terhapus.',
      ),
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
  return ok == true;
}

class _AccountEditorResult {
  final AccountModel? saved;
  final String? deletedId;
  _AccountEditorResult.save(this.saved) : deletedId = null;
  _AccountEditorResult.delete(this.deletedId) : saved = null;
}

typedef AccountEditorResult = _AccountEditorResult;

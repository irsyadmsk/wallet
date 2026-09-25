import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';
import 'package:financial_recording/presentation/account_detail/view/account_detail_view.dart';
import 'package:financial_recording/presentation/accounts/controller/accounts_controller.dart';
import 'package:financial_recording/presentation/accounts/widget/account_editor_sheet.dart';
import 'package:financial_recording/data/services/emoney_nfc_service.dart';
import 'package:financial_recording/presentation/emoney_nfc/view/emoney_nfc_view.dart';
import 'package:financial_recording/presentation/form_tx/view/form_tx_view.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/shared/widget/account_avatar.dart';
import 'package:financial_recording/util/money/money_format.dart';

class AccountsView extends StatelessWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AccountsController(), tag: 'accounts');
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Akun'),
        actions: [
          if (EmoneyNfcService.isSupported)
            IconButton(
              tooltip: 'Pindai Kartu E-Money (NFC)',
              icon: const Icon(Icons.nfc_rounded),
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const EmoneyNfcView()),
                );
                if (created == true) c.refresh();
              },
            ),
          IconButton(
            tooltip: 'Hitung ulang saldo',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => c.recomputeBalances(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showAdaptiveSheet<AccountEditorResult>(
            context,
            builder: (_) => const AccountEditorSheet(),
          );
          if (result?.saved != null) await c.saveAccount(result!.saved!);
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: SingleChildScrollView(
        child: ContentShell(
          child: Obx(() {
            final groups = c.grouped;
            if (groups.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('Belum ada akun. Tambahkan dengan tombol +.'),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        c.netWorth.value.rupiah,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: c.netWorth.value >= 0 ? colors.income : colors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final group in AccountGroupType.displayOrder)
                  if (groups[group]?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: _GroupSection(group: group, accounts: groups[group]!, controller: c),
                    ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group, required this.accounts, required this.controller});
  final AccountGroupType group;
  final List<AccountModel> accounts;
  final AccountsController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtotal = accounts.fold<int>(0, (s, a) => s + a.cachedBalance);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(group.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(group.label, style: Theme.of(context).textTheme.titleMedium)),
                Text(
                  subtotal.rupiah,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: subtotal < 0 ? colors.danger : colors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            // One column: a balance should sit at the row's right edge, not
            // float mid-card as it did in a half-empty two-column grid.
            Column(
              children: [
                for (final a in accounts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => Get.to(() => AccountDetailView(accountId: a.id)),
                    onLongPress: () async {
                      final result = await showAdaptiveSheet<AccountEditorResult>(
                        context,
                        builder: (_) => AccountEditorSheet(existing: a),
                      );
                      if (result?.saved != null) await controller.saveAccount(result!.saved!);
                      if (result?.deletedId != null) await controller.deleteAccount(result!.deletedId!);
                    },
                    leading: AccountAvatar(account: a, radius: 18),
                    title: Text(a.name),
                    subtitle: a.isLiability && a.dueDay != null
                        ? Text('Jatuh tempo tgl ${a.dueDay}', style: TextStyle(fontSize: 11, color: colors.warning))
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          a.cachedBalance.rupiah,
                          style: AppTypography.numeric(
                            size: 15,
                            weight: FontWeight.w600,
                            color: a.cachedBalance < 0 ? colors.danger : colors.textPrimary,
                          ),
                        ),
                        if (a.isLiability) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Bayar ${a.name}',
                            icon: Icon(Icons.payments_rounded, size: 18, color: colors.primary),
                            onPressed: () async {
                              final saved = await showAdaptiveSheet<bool>(
                                context,
                                builder: (_) => FormTxView(
                                  initialType: TxType.transfer,
                                  initialToAccountId: a.id,
                                  initialMemo: 'Bayar ${a.name}',
                                ),
                              );
                              if (saved == true) controller.refresh();
                            },
                          ),
                        ],
                      ],
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

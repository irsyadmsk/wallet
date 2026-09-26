import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/shared/widget/market_card.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/services/currency/currency.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/repositories/account_group_repository.dart';
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
              tooltip: 'Cek saldo kartu (NFC)',
              icon: const Icon(Icons.contactless_rounded),
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
          // In the app bar rather than a FAB: on phones a FAB sat under the
          // floating bottom bar and couldn't be tapped.
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: FilledButton.tonalIcon(
              onPressed: () => _addAccount(context, c),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ContentShell(
          child: Obx(() {
            final groups = c.grouped;
            if (groups.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('Belum ada akun. Tambahkan dengan tombol "Tambah" di atas.'),
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
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.lg),
                  child: MarketCard(),
                ),
                for (final (group, accounts) in groups)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _GroupSection(group: group, accounts: accounts, controller: c),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

Future<void> _addAccount(BuildContext context, AccountsController c) async {
  final result = await showAdaptiveSheet<AccountEditorResult>(
    context,
    builder: (_) => const AccountEditorSheet(),
  );
  if (result?.saved != null) await c.saveAccount(result!.saved!);
}

Future<void> _editAccount(BuildContext context, AccountsController c, AccountModel a) async {
  final result = await showAdaptiveSheet<AccountEditorResult>(
    context,
    builder: (_) => AccountEditorSheet(existing: a),
  );
  if (result?.saved != null) await c.saveAccount(result!.saved!);
  if (result?.deletedId != null) await c.deleteAccount(result!.deletedId!);
}

enum _AccountAction { edit, delete }

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group, required this.accounts, required this.controller});
  final AccountGroup group;
  final List<AccountModel> accounts;
  final AccountsController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Rupiah value of the group, whatever currencies its accounts hold.
    final subtotal = accounts.fold<int>(0, (s, a) => s + a.balanceIdr);

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
                    onTap: () async {
                      await Get.to(() => AccountDetailView(accountId: a.id));
                      controller.refresh();
                    },
                    onLongPress: () => _editAccount(context, controller, a),
                    leading: AccountAvatar(account: a, radius: 18),
                    title: Text(a.name),
                    subtitle: a.currencyCode != Currency.idr
                        ? Text('≈ ${a.balanceIdr.rupiah}', style: TextStyle(fontSize: 11.5, color: colors.textSecondary))
                        : a.isLiability && a.dueDay != null
                            ? Text('Jatuh tempo tgl ${a.dueDay}', style: TextStyle(fontSize: 11, color: colors.warning))
                            : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          a.cachedBalance.money(a.currencyCode),
                          style: AppTypography.numeric(
                            size: 15,
                            weight: FontWeight.w600,
                            color: a.cachedBalance < 0 ? colors.danger : colors.textPrimary,
                          ),
                        ),
                        PopupMenuButton<_AccountAction>(
                          tooltip: 'Opsi ${a.name}',
                          icon: Icon(Icons.more_vert_rounded, size: 20, color: colors.textSecondary),
                          onSelected: (action) async {
                            switch (action) {
                              case _AccountAction.edit:
                                await _editAccount(context, controller, a);
                              case _AccountAction.delete:
                                if (await confirmDeleteAccount(context, a)) await controller.deleteAccount(a.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: _AccountAction.edit,
                              child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Ubah'), contentPadding: EdgeInsets.zero),
                            ),
                            PopupMenuItem(
                              value: _AccountAction.delete,
                              child: ListTile(leading: Icon(Icons.delete_outline_rounded), title: Text('Hapus'), contentPadding: EdgeInsets.zero),
                            ),
                          ],
                        ),
                        if (a.isLiability) ...[
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

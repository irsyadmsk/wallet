import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/util/money/money_format.dart';

/// Restore or permanently remove soft-deleted accounts. Their transaction
/// history is never touched — deleting an account only hides it.
class TrashAccountsView extends StatefulWidget {
  const TrashAccountsView({super.key});

  @override
  State<TrashAccountsView> createState() => _TrashAccountsViewState();
}

class _TrashAccountsViewState extends State<TrashAccountsView> {
  final _repo = AccountRepository();
  late List<AccountModel> _deleted = _repo.deletedAccounts();

  void _refresh() => setState(() => _deleted = _repo.deletedAccounts());

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Akun Terhapus')),
      body: SingleChildScrollView(
        child: ContentShell(
          child: _deleted.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Center(
                    child: Text('Tidak ada akun yang dihapus.', style: TextStyle(color: colors.textSecondary)),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final a in _deleted)
                      Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          title: Text(a.name),
                          subtitle: Text(
                            'Saldo terakhir ${a.cachedBalance.rupiah} · dihapus ${DateFormat('d MMM y, HH:mm', 'id_ID').format(a.deletedAt!)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Pulihkan',
                                icon: Icon(Icons.restore_rounded, color: colors.primary),
                                onPressed: () async {
                                  await _repo.restore(a.id);
                                  _refresh();
                                },
                              ),
                              IconButton(
                                tooltip: 'Hapus permanen',
                                icon: Icon(Icons.delete_forever_rounded, color: colors.danger),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Hapus permanen?'),
                                      content: Text('"${a.name}" tidak bisa dipulihkan lagi setelah ini.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
                                        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await _repo.purge(a.id);
                                    _refresh();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
        ),
      ),
    );
  }
}

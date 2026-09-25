import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/app/sync_controller.dart';
import 'package:financial_recording/presentation/auth/controller/auth_controller.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';

/// Settings › "Zona bahaya": erase all financial data (keep the account),
/// or delete the account itself. Both need the word HAPUS typed out.
class DangerZone extends StatelessWidget {
  const DangerZone({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sync = Get.find<SyncController>();

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.delete_sweep_rounded, color: colors.danger),
            title: Text('Hapus semua data', style: TextStyle(color: colors.danger, fontWeight: FontWeight.w600)),
            subtitle: Obx(() => Text(
                  sync.inFamily && sync.isFamilyOwner
                      ? 'Mengosongkan buku kas keluarga untuk semua anggota. Akun tetap ada.'
                      : sync.inFamily
                          ? 'Mengosongkan buku kas pribadi Anda. Buku kas keluarga tidak terpengaruh.'
                          : 'Semua akun, transaksi, anggaran, dan catatan dihapus di semua perangkat. Akun tetap ada.',
                )),
            onTap: () => _wipe(context, sync),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.person_remove_rounded, color: colors.danger),
            title: Text('Hapus akun permanen', style: TextStyle(color: colors.danger, fontWeight: FontWeight.w600)),
            subtitle: const Text('Akun dan seluruh datanya dihapus dari server. Tidak bisa dibatalkan.'),
            onTap: () => _deleteAccount(context),
          ),
        ],
      ),
    );
  }

  Future<void> _wipe(BuildContext context, SyncController sync) async {
    final familyBook = sync.inFamily && sync.isFamilyOwner;
    final ok = await confirmTyped(
      context,
      title: 'Hapus semua data?',
      body: familyBook
          ? 'Seluruh isi buku kas keluarga akan dihapus di semua perangkat, termasuk milik anggota. '
              'Akun Anda dan keanggotaan keluarga tetap ada.'
          : 'Semua akun, transaksi, anggaran, target, utang, memo, dan portofolio kripto akan dihapus '
              'di semua perangkat Anda. Akun login tetap ada dan Anda mulai dari awal.',
      action: 'Hapus semua data',
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await _withProgress(context, sync.wipeAllData());
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Semua data sudah dihapus.')));
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final ok = await confirmTyped(
      context,
      title: 'Hapus akun permanen?',
      body: 'Akun, seluruh data keuangan, dan keluarga yang Anda miliki akan dihapus dari server dan '
          'tidak bisa dipulihkan. Anggota keluarga kembali ke buku kas pribadi masing-masing.',
      action: 'Hapus akun',
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await _withProgress(context, Get.find<AuthController>().deleteAccount());
    if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
  }

  Future<T> _withProgress<T>(BuildContext context, Future<T> work) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      return await work;
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

/// Asks for the word HAPUS before a destructive action.
Future<bool> confirmTyped(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _TypedConfirmDialog(title: title, body: body, action: action),
  );
  return ok == true;
}

/// Owns its text controller, so it's disposed only after the dialog's exit
/// animation has finished drawing the field.
class _TypedConfirmDialog extends StatefulWidget {
  const _TypedConfirmDialog({required this.title, required this.body, required this.action});
  final String title;
  final String body;
  final String action;

  @override
  State<_TypedConfirmDialog> createState() => _TypedConfirmDialogState();
}

class _TypedConfirmDialogState extends State<_TypedConfirmDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _confirmed => _ctrl.text.trim().toUpperCase() == 'HAPUS';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.body),
            const SizedBox(height: 16),
            const Text('Ketik HAPUS untuk melanjutkan.', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'HAPUS'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.colors.danger),
          onPressed: _confirmed ? () => Navigator.pop(context, true) : null,
          child: Text(widget.action),
        ),
      ],
    );
  }
}

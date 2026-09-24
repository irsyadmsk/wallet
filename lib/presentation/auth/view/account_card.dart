import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/app/shell_controller.dart';
import 'package:financial_recording/app/sync_controller.dart';
import 'package:financial_recording/presentation/auth/controller/auth_controller.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';

/// Signed-in account summary for Settings: identity, family, sync state,
/// and the account actions (rename, change password, sign out).
class AccountCard extends StatelessWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final sync = Get.find<SyncController>();
    final c = context.colors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final name = auth.displayName;
          final last = sync.lastSyncAt.value;
          final family = sync.household.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: c.textPrimary,
                    child: Text(
                      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                      style: TextStyle(color: c.surfaceAlt, fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                        Text(auth.user.value?.email ?? '',
                            style: TextStyle(color: c.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  WIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Ubah nama panggilan',
                    onPressed: () => _rename(context, auth),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StatusRow(
                icon: sync.syncing.value ? Icons.sync_rounded : (sync.errorText.value == null ? Icons.cloud_done_outlined : Icons.cloud_off_outlined),
                spinning: sync.syncing.value,
                color: sync.errorText.value == null ? c.success : c.warning,
                text: sync.syncing.value
                    ? 'Menyinkronkan…'
                    : sync.errorText.value ?? (last == null ? 'Belum pernah sinkron' : 'Tersinkron ${_relative(last)} · otomatis'),
              ),
              const SizedBox(height: 8),
              _StatusRow(
                icon: Icons.diversity_3_outlined,
                color: c.textSecondary,
                text: family == null
                    ? 'Belum tergabung dalam keluarga'
                    : 'Keluarga ${family.name} · ${sync.members.length} anggota',
                action: TextButton(
                  onPressed: () => Get.find<ShellController>().goTo(AppPage.family),
                  child: Text(family == null ? 'Buat / gabung' : 'Kelola'),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  WButton(
                    label: 'Sinkronkan',
                    icon: Icons.sync_rounded,
                    variant: WButtonVariant.tonal,
                    size: WButtonSize.small,
                    loading: sync.syncing.value,
                    onPressed: sync.syncNow,
                  ),
                  WButton(
                    label: 'Ubah kata sandi',
                    icon: Icons.key_outlined,
                    variant: WButtonVariant.outline,
                    size: WButtonSize.small,
                    onPressed: () => _changePassword(context, auth),
                  ),
                  WButton(
                    label: 'Keluar',
                    icon: Icons.logout_rounded,
                    variant: WButtonVariant.ghost,
                    size: WButtonSize.small,
                    loading: auth.busy.value,
                    onPressed: () => confirmSignOut(context),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  static String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }

  Future<void> _rename(BuildContext context, AuthController auth) async {
    final ctrl = TextEditingController(text: auth.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nama panggilan'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(helperText: 'Dilihat anggota keluarga dan tercatat di transaksi baru.'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Simpan')),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) await auth.updateDisplayName(name);
  }

  Future<void> _changePassword(BuildContext context, AuthController auth) async {
    final ctrl = TextEditingController();
    final key = GlobalKey<FormState>();
    final pw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah kata sandi'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(labelText: 'Kata sandi baru'),
            validator: (v) => (v == null || v.length < 8) ? 'Minimal 8 karakter.' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (key.currentState?.validate() ?? false) Navigator.pop(ctx, ctrl.text);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (pw == null) return;
    final ok = await auth.updatePassword(pw);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Kata sandi diperbarui.' : (auth.errorText.value ?? 'Gagal memperbarui.'))),
      );
    }
  }
}

/// Sign-out with the consequences spelled out: local data is removed from
/// this device after a final sync; if that sync fails, a second prompt
/// warns that unsynced edits would be lost.
Future<void> confirmSignOut(BuildContext context) async {
  final auth = Get.find<AuthController>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Keluar dari Wallet?'),
      content: const Text(
        'Data akan disinkronkan terlebih dahulu, lalu dihapus dari perangkat ini. '
        'Semua catatan tetap aman di akun Anda dan kembali saat Anda masuk lagi.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
      ],
    ),
  );
  if (ok != true) return;
  final err = await auth.signOut();
  if (err == null || !context.mounted) return;
  final force = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sinkronisasi gagal'),
      content: Text(
        '$err\n\nJika tetap keluar, catatan yang belum tersinkron di perangkat ini akan hilang.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tetap masuk')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ctx.colors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Keluar & hapus'),
        ),
      ],
    ),
  );
  if (force == true) await auth.signOut(force: true);
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.icon, required this.color, required this.text, this.action, this.spinning = false});
  final IconData icon;
  final Color color;
  final String text;
  final Widget? action;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    Widget i = Icon(icon, size: 18, color: color);
    if (spinning) {
      i = SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color));
    }
    return Row(
      children: [
        i,
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13.5, color: context.colors.textSecondary))),
        if (action != null) action!,
      ],
    );
  }
}

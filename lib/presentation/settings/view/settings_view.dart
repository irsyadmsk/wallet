import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:financial_recording/app/shell_controller.dart';
import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/presentation/auth/controller/auth_controller.dart';
import 'package:financial_recording/presentation/auth/view/auth_sheet.dart';
import 'package:financial_recording/presentation/import_mmbak/view/import_mmbak_view.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/presentation/settings/controller/settings_controller.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/theme/art_icon_theme.dart';
import 'package:financial_recording/shared/theme/theme_controller.dart';
import 'package:financial_recording/shared/widget/art_icon.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SettingsController(), tag: 'settings');
    final theme = Get.find<ThemeController>();
    final shell = Get.find<ShellController>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Pengaturan'),
      ),
      body: SingleChildScrollView(
        child: ContentShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel('Akun & Sinkronisasi'),
              const _AccountSyncCard(),
              const SizedBox(height: AppSpacing.lg),

              _SectionLabel('Mode Tampilan'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Obx(() => SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('Sistem'),
                            icon: Icon(Icons.brightness_auto_rounded),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Terang'),
                            icon: Icon(Icons.light_mode_rounded),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Gelap'),
                            icon: Icon(Icons.dark_mode_rounded),
                          ),
                        ],
                        selected: {theme.themeMode.value},
                        onSelectionChanged: (s) => theme.setThemeMode(s.first),
                      )),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              _SectionLabel('Palet Warna Zen Menenangkan'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih suasana warna yang menyejukkan mata dan pikiran:',
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Obx(() => Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPaletteChip(theme, 'Irsyads Teal', AppColors.presetIrsyads),
                              _buildPaletteChip(theme, 'Sage Calm', AppColors.presetSage),
                              _buildPaletteChip(theme, 'Ocean Slate', AppColors.presetOcean),
                              _buildPaletteChip(theme, 'Warm Sand', AppColors.presetSand),
                              _buildPaletteChip(theme, 'Lavender Dusk', AppColors.presetLavender),
                              _buildPaletteChip(theme, 'Forest Emerald', AppColors.presetForest),
                            ],
                          )),
                      const Divider(height: AppSpacing.xl),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.palette_rounded, color: colors.primary, size: 20),
                        ),
                        title: const Text('Warna Kustom Lainnya'),
                        trailing: Obx(() => CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.seedColor.value,
                              child: const Icon(Icons.colorize_rounded, size: 14, color: Colors.white),
                            )),
                        onTap: () => _pickColor(context, theme),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              _SectionLabel('Desain Ikon ART+ Adaptif'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih siluet geometris untuk seluruh ikon dan avatar aplikasi:',
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Obx(() {
                        final current = theme.artShape.value;
                        return Column(
                          children: ArtShape.values.map((shape) {
                            final isSelected = current == shape;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: InkWell(
                                onTap: () => theme.setArtShape(shape),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colors.primaryContainer.withValues(alpha: 0.35)
                                        : colors.surfaceAlt.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? colors.primary : colors.border.withValues(alpha: 0.4),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ArtIcon(
                                        size: 40,
                                        shapeOverride: shape,
                                        backgroundColor: isSelected ? colors.primary : colors.surfaceRaised,
                                        borderColor: isSelected ? colors.primary : colors.border,
                                        icon: shape.previewIcon,
                                        iconColor: isSelected ? Colors.white : colors.textPrimary,
                                        showAura: isSelected,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              shape.label,
                                              style: TextStyle(
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                fontSize: 14,
                                                color: isSelected ? colors.primary : colors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              shape.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Radio<ArtShape>(
                                        value: shape,
                                        groupValue: current,
                                        onChanged: (val) {
                                          if (val != null) theme.setArtShape(val);
                                        },
                                        activeColor: colors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              _SectionLabel('Fitur & Kelola Data'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.handshake_rounded),
                      title: const Text('Utang & Piutang'),
                      subtitle: const Text('Catat pinjaman, cicilan, dan jatuh tempo'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => shell.goTo(6),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.flag_rounded),
                      title: const Text('Target Tabungan (Goals)'),
                      subtitle: const Text('Pantau impian finansial dan progres tabungan'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => shell.goTo(5),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.autorenew_rounded),
                      title: const Text('Transaksi Berulang'),
                      subtitle: const Text('Kelola tagihan rutin dan jadwal otomatis'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => shell.goTo(7),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.category_rounded),
                      title: const Text('Kategori Transaksi'),
                      subtitle: const Text('Atur hierarki kategori pemasukan & pengeluaran'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => shell.goTo(8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              _SectionLabel('Cadangan & Impor'),
              Card(
                child: Obx(() => Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.upload_file_rounded),
                          title: const Text('Impor dari Money Manager (.mmbak)'),
                          subtitle: const Text('Ganti atau gabungkan data dari file cadangan .mmbak'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          enabled: !c.busy.value,
                          onTap: () => Get.to(() => const ImportMmbakView()),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.save_alt_rounded),
                          title: const Text('Simpan Cadangan (JSON)'),
                          subtitle: const Text('Ekspor seluruh catatan dan pengaturan'),
                          trailing: const Icon(Icons.download_rounded),
                          enabled: !c.busy.value,
                          onTap: c.exportBackup,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.restore_rounded),
                          title: const Text('Pulihkan Cadangan (JSON)'),
                          subtitle: const Text('Kembalikan data dari berkas cadangan JSON'),
                          trailing: const Icon(Icons.history_rounded),
                          enabled: !c.busy.value,
                          onTap: () async {
                            final ok = await c.restoreBackup();
                            if (ok) {
                              if (Get.isRegistered<ThemeController>()) {
                                Get.find<ThemeController>().onInit();
                              }
                            }
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.file_download_rounded),
                          title: const Text('Ekspor Transaksi ke CSV'),
                          subtitle: const Text('Format spreadsheet yang kompatibel dengan Excel/Sheets'),
                          trailing: const Icon(Icons.table_chart_rounded),
                          enabled: !c.busy.value,
                          onTap: c.exportCsv,
                        ),
                      ],
                    )),
              ),
              Obx(() => c.lastMessage.value.isEmpty
                  ? const SizedBox()
                  : Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(c.lastMessage.value, style: TextStyle(color: colors.textSecondary)),
                    )),
              const SizedBox(height: AppSpacing.lg),

              _SectionLabel('Tentang'),
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.spa_rounded, color: colors.primary),
                  ),
                  title: Text(AppConfig.appName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('v${AppConfig.appVersion} · ${AppConfig.appAuthor}'),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaletteChip(ThemeController theme, String label, Color color) {
    final isSelected = theme.seedColor.value.toARGB32() == color.toARGB32();
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      avatar: CircleAvatar(radius: 8, backgroundColor: color),
      onSelected: (_) => theme.setSeedColor(color),
      showCheckmark: false,
    );
  }

  void _pickColor(BuildContext context, ThemeController theme) {
    Color picked = theme.seedColor.value;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih warna kustom'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: picked,
            onColorChanged: (c) => picked = c,
            enableAlpha: false,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              theme.setSeedColor(picked);
              Navigator.of(ctx).pop();
            },
            child: const Text('Pakai'),
          ),
        ],
      ),
    );
  }
}

class _AccountSyncCard extends StatelessWidget {
  const _AccountSyncCard();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final colors = context.colors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Obx(() {
          if (!auth.isSignedIn) {
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.cloud_off_rounded, color: colors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Belum masuk', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        'Masuk untuk menyinkronkan data ke perangkat lain.',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => showAdaptiveSheet(context, builder: (_) => const AuthSheet()),
                  child: const Text('Masuk'),
                ),
              ],
            );
          }

          final lastSync = auth.lastSyncAt.value;
          final lastSyncText = lastSync == null
              ? 'Belum pernah sinkron'
              : 'Sinkron terakhir: ${_formatRelative(lastSync)}';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.cloud_done_rounded, color: colors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user.value?.email ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(lastSyncText, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: auth.syncing.value ? null : auth.syncNow,
                      icon: auth.syncing.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(auth.syncing.value ? 'Menyinkronkan...' : 'Sinkronkan Sekarang'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: auth.signOut,
                    child: const Text('Keluar'),
                  ),
                ],
              ),
              if (auth.errorText.value != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  auth.errorText.value!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  String _formatRelative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
      child: Text(
        text,
        style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

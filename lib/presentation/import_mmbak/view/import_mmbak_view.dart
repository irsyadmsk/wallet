import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/data/import/mmbak_models.dart';
import 'package:financial_recording/presentation/import_mmbak/controller/import_mmbak_controller.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/zen_background.dart';
import 'package:financial_recording/util/money/money_format.dart';

class ImportMmbakView extends StatelessWidget {
  const ImportMmbakView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ImportMmbakController(), tag: 'import_mmbak');
    final colors = context.colors;

    return ZenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Impor dari Money Manager'),
        ),
      body: SingleChildScrollView(
        child: ContentShell(
          child: Obx(() {
            if (!c.isSupported) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: colors.warning),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Impor langsung file .mmbak hanya tersedia di aplikasi mobile/desktop, '
                        'bukan di pratinjau web ini. Gunakan menu "Pulihkan cadangan (JSON)" di '
                        'Pengaturan sebagai gantinya.',
                      ),
                    ],
                  ),
                ),
              );
            }

            switch (c.step.value) {
              case ImportStep.pickFile:
                return _PickStep(controller: c);
              case ImportStep.preview:
                return c.preview.value == null
                    ? const _Progress()
                    : _PreviewStep(controller: c, preview: c.preview.value!);
              case ImportStep.importing:
                return const _Progress();
              case ImportStep.done:
                return _DoneStep(controller: c, report: c.report.value!);
              case ImportStep.error:
                return _ErrorStep(controller: c);
            }
          }),
        ),
      ),
    ),
  );
  }
}

class _PickStep extends StatelessWidget {
  const _PickStep({required this.controller});
  final ImportMmbakController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih file .mmbak', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'File cadangan aplikasi Money Manager (format SQLite) — biasanya berada di '
              'folder Download atau Google Drive > MoneyManager.',
              style: TextStyle(color: context.colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: controller.pickAndAnalyze,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Pilih file'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ImportMmbakController>(tag: 'import_mmbak');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Obx(() => Column(
              children: [
                LinearProgressIndicator(value: c.progress.value == 0 ? null : c.progress.value),
                const SizedBox(height: AppSpacing.md),
                Text(c.progressPhase.value),
              ],
            )),
      ),
    );
  }
}

class _PreviewStep extends StatelessWidget {
  const _PreviewStep({required this.controller, required this.preview});
  final ImportMmbakController controller;
  final MmbakPreview preview;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final df = DateFormat('d MMM y', 'id_ID');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ringkasan data', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                _Row('Akun', '${preview.accounts.length}'),
                _Row('Kategori', '${preview.categories.length}'),
                _Row('Transaksi', '${preview.transactions.length} (masuk ${preview.incomeCount}, keluar ${preview.expenseCount}, transfer ${preview.transferCount})'),
                if (preview.earliestDate != null && preview.latestDate != null)
                  _Row('Rentang tanggal', '${df.format(preview.earliestDate!)} — ${df.format(preview.latestDate!)}'),
                _Row('Saldo bersih', preview.netWorth.rupiah),
                if (preview.warnings.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Peringatan (${preview.warnings.length})', style: TextStyle(color: colors.warning, fontWeight: FontWeight.w600)),
                  for (final w in preview.warnings) Text('• $w', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mode impor', style: Theme.of(context).textTheme.titleMedium),
                Obx(() => RadioGroup<ImportMode>(
                      groupValue: controller.mode.value,
                      onChanged: (v) => controller.mode.value = v!,
                      child: const Column(
                        children: [
                          RadioListTile<ImportMode>(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Ganti semua data lokal'),
                            subtitle: Text('Semua akun, kategori, dan transaksi saat ini akan dihapus.'),
                            value: ImportMode.replaceAll,
                          ),
                          RadioListTile<ImportMode>(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Gabungkan dengan data yang ada'),
                            subtitle: Text('Hanya menambahkan transaksi baru berdasarkan id sumber.'),
                            value: ImportMode.merge,
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => _confirmAndApply(context, controller),
          child: const Text('Mulai impor'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(onPressed: controller.reset, child: const Text('Batal')),
      ],
    );
  }

  Future<void> _confirmAndApply(BuildContext context, ImportMmbakController c) async {
    if (c.mode.value == ImportMode.replaceAll) {
      var confirmed = false;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Hapus semua data lokal?'),
            content: Row(
              children: [
                Checkbox(value: confirmed, onChanged: (v) => setState(() => confirmed = v ?? false)),
                const Expanded(child: Text('Saya paham semua data lokal saat ini akan dihapus dan diganti.')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
              FilledButton(
                onPressed: confirmed ? () => Navigator.of(ctx).pop(true) : null,
                child: const Text('Lanjutkan'),
              ),
            ],
          ),
        ),
      );
      if (ok != true) return;
    }
    await c.apply();
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.controller, required this.report});
  final ImportMmbakController controller;
  final MmbakImportReport report;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, color: colors.success, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text('Impor selesai', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            _Row('Akun', '${report.accountCount}'),
            _Row('Kategori', '${report.categoryCount}'),
            _Row('Transaksi', '${report.transactionCount}'),
            _Row('Tag', '${report.tagCount}'),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Selesai')),
          ],
        ),
      ),
    );
  }
}

class _ErrorStep extends StatelessWidget {
  const _ErrorStep({required this.controller});
  final ImportMmbakController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: context.colors.danger),
            const SizedBox(height: AppSpacing.sm),
            Obx(() => Text(controller.errorMessage.value)),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: controller.reset, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.colors.textSecondary)),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

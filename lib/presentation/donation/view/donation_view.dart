import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';

const _qrisAsset = 'assets/donation/qris.png';

/// "Dukung Pengembang": a voluntary donation through the developer's QRIS.
/// Not shown to Play Store installs (see `kDonationsEnabled`).
class DonationView extends StatelessWidget {
  const DonationView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dukung Pengembang')),
      body: SingleChildScrollView(
        child: ContentShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Terima kasih sudah memakai Wallet', style: t.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Wallet gratis, tanpa iklan, dan tidak menjual data Anda. Jika bermanfaat, Anda bisa ikut '
                'menanggung biaya server dan pengembangan dengan donasi seikhlasnya lewat QRIS — '
                'bisa dibayar dari aplikasi bank atau dompet digital apa pun.',
                style: TextStyle(color: colors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _zoom(context),
                      child: Image.asset(
                        _qrisAsset,
                        semanticLabel: 'Kode QRIS donasi atas nama DEIRSYAD',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ketuk gambar untuk memperbesar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: FilledButton.tonalIcon(
                  onPressed: () => _save(context),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Simpan gambar QRIS'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Cara donasi', style: t.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final (i, step) in const [
                'Buka aplikasi bank atau dompet digital berlogo QRIS (GoPay, OVO, DANA, ShopeePay, m-banking, dll.).',
                'Pilih "Scan/Bayar", lalu pindai kode di atas dari HP lain — atau simpan gambarnya dan pilih dari galeri.',
                'Pastikan nama penerima DEIRSYAD, isi nominal seikhlasnya, lalu bayar.',
              ].indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: colors.primaryContainer,
                        child: Text('${i + 1}', style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(step, style: const TextStyle(height: 1.45))),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Donasi bersifat sukarela dan tidak membuka fitur apa pun — semua fitur Wallet tetap gratis.',
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  void _zoom(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          maxScale: 4,
          child: GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Image.asset(_qrisAsset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await rootBundle.load(_qrisAsset);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan QRIS donasi',
        fileName: 'QRIS-donasi-Wallet.png',
        type: FileType.image,
        bytes: data.buffer.asUint8List(),
      );
      // On the web the file is downloaded directly and no path comes back.
      if (path != null || kIsWeb) {
        messenger.showSnackBar(const SnackBar(content: Text('Gambar QRIS disimpan.')));
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Gagal menyimpan. Ambil tangkapan layar sebagai gantinya.')));
    }
  }
}

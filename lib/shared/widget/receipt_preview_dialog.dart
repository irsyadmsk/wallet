import 'dart:io';
import 'package:flutter/material.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';

/// Interactive modal/sheet to view high-resolution receipt images with pinch-to-zoom.
class ReceiptPreviewDialog extends StatelessWidget {
  const ReceiptPreviewDialog({
    super.key,
    required this.imagePath,
    this.title = 'Bukti Transaksi / Struk',
    this.subtitle,
    this.onDelete,
  });

  final String imagePath;
  final String title;
  final String? subtitle;
  final VoidCallback? onDelete;

  static Future<void> show(
    BuildContext context, {
    required String imagePath,
    String title = 'Bukti Transaksi / Struk',
    String? subtitle,
    VoidCallback? onDelete,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => ReceiptPreviewDialog(
        imagePath: imagePath,
        title: title,
        subtitle: subtitle,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final file = File(imagePath);
    final exists = file.existsSync();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Container(
          color: colors.surface,
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.6))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: colors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty)
                            Text(
                              subtitle!,
                              style: TextStyle(color: colors.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (onDelete != null)
                      IconButton(
                        tooltip: 'Hapus struk',
                        icon: Icon(Icons.delete_outline_rounded, color: colors.danger),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDelete!();
                        },
                      ),
                    IconButton(
                      tooltip: 'Tutup',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Image content with pinch to zoom
              Flexible(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.04),
                  width: double.infinity,
                  child: exists
                      ? InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.file(
                              file,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _buildErrorWidget(colors),
                            ),
                          ),
                        )
                      : _buildErrorWidget(colors),
                ),
              ),

              // Bottom hint
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  border: Border(top: BorderSide(color: colors.border.withValues(alpha: 0.5))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pinch_rounded, size: 16, color: colors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      'Cubit atau scroll untuk memperbesar',
                      style: TextStyle(color: colors.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(AppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_rounded, size: 48, color: colors.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'File struk tidak dapat dimuat atau telah dipindahkan.',
              style: TextStyle(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/core.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/data/services/receipt_ocr_service.dart';
import 'package:financial_recording/data/services/receipt_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/receipt_preview_dialog.dart';
import 'package:financial_recording/util/money/money_format.dart';

/// Unified add/edit form for income, expense and transfer — with receipt attachment support.
class FormTxView extends StatefulWidget {
  const FormTxView({
    super.key,
    this.existing,
    this.initialType = TxType.expense,
    this.initialAccountId,
    this.initialToAccountId,
    this.initialMemo,
  });

  final TxModel? existing;
  final TxType initialType;

  /// Pre-fills the source account (or "dari akun" for a transfer) on a new
  /// transaction — e.g. opening the form to pay off a specific card.
  final String? initialAccountId;

  /// Pre-fills the destination account of a new transfer.
  final String? initialToAccountId;
  final String? initialMemo;

  @override
  State<FormTxView> createState() => _FormTxViewState();
}

class _FormTxViewState extends State<FormTxView> {
  final _accounts = AccountRepository();
  final _categories = TxCategoryRepository();
  final _ledger = LedgerService();
  final _receipts = ReceiptService();
  final _ocr = ReceiptOcrService();
  bool scanning = false;

  late TxType type = widget.existing?.type ?? widget.initialType;
  late String? accountId =
      widget.existing?.accountId ?? widget.initialAccountId ?? _accounts.all().firstOrNull?.id;
  late String? toAccountId = widget.existing?.toAccountId ?? widget.initialToAccountId;
  late String? categoryId = widget.existing?.categoryId;
  late int amount = widget.existing?.amount ?? 0;
  late DateTime date = widget.existing?.date ?? DateTime.now();
  late TimeOfDay time = TimeOfDay.fromDateTime(widget.existing?.date ?? DateTime.now());
  late String memo = widget.existing?.memo ?? widget.initialMemo ?? '';
  late String? imagePath = widget.existing?.imagePath;
  bool isNewImagePicked = false;
  bool saving = false;

  bool get isEditing => widget.existing != null;

  DateTime get _combinedDateTime => DateTime(date.year, date.month, date.day, time.hour, time.minute);

  List<Map<String, dynamic>> get _accountItems =>
      [for (final a in _accounts.all()) {'value': a.id, 'label': a.name}];

  List<Map<String, dynamic>> get _categoryItems {
    final typeCode = type == TxType.income ? 0 : 1;
    final roots = _categories.roots(typeCode);
    final items = <Map<String, dynamic>>[];
    for (final r in roots) {
      items.add({'value': r.id, 'label': r.displayName});
      for (final child in _categories.childrenOf(r.id)) {
        items.add({'value': child.id, 'label': '   ↳ ${child.name}'});
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar on top of bottom sheet
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isEditing ? 'Ubah transaksi' : 'Transaksi baru',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Segmented Type Selector
            SegmentedButton<TxType>(
              segments: const [
                ButtonSegment(value: TxType.expense, label: Text('Pengeluaran'), icon: Icon(Icons.north_east_rounded)),
                ButtonSegment(value: TxType.income, label: Text('Pemasukan'), icon: Icon(Icons.south_west_rounded)),
                ButtonSegment(value: TxType.transfer, label: Text('Transfer'), icon: Icon(Icons.swap_horiz_rounded)),
              ],
              selected: {type},
              onSelectionChanged: (s) => setState(() {
                type = s.first;
                categoryId = null;
              }),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected) ? colors.primaryContainer : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Number field
            QNumberField(
              label: 'Jumlah (Rp)',
              value: amount == 0 ? '' : amount.toString(),
              locale: 'id_ID',
              onChanged: (v) => amount = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
            ),

            // Account picker
            QDropdownField(
              label: type == TxType.transfer ? 'Dari akun' : 'Akun',
              value: accountId,
              items: _accountItems,
              onChanged: (v, _) => setState(() => accountId = v as String?),
            ),

            if (type == TxType.transfer)
              QDropdownField(
                label: 'Ke akun',
                value: toAccountId,
                items: [
                  for (final item in _accountItems)
                    if (item['value'] != accountId) item,
                ],
                onChanged: (v, _) => setState(() => toAccountId = v as String?),
              )
            else
              QDropdownField(
                label: 'Kategori',
                value: categoryId,
                items: _categoryItems,
                onChanged: (v, _) => setState(() => categoryId = v as String?),
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: QDatePicker(
                    label: 'Tanggal',
                    value: date,
                    onChanged: (v) => date = v,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: QTimePicker(
                    label: 'Jam',
                    value: time,
                    onChanged: (v) => time = v ?? time,
                  ),
                ),
              ],
            ),

            QMemoField(
              label: 'Catatan (opsional)',
              value: memo,
              onChanged: (v) => memo = v,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Receipt attachment section
            _buildReceiptSection(context, colors),

            const SizedBox(height: AppSpacing.xl),

            // Submit and Delete buttons
            Row(
              children: [
                if (isEditing) ...[
                  Expanded(
                    child: QOutlineButton(
                      label: 'Hapus',
                      color: colors.danger,
                      onPressed: saving ? () {} : _delete,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  flex: isEditing ? 2 : 1,
                  child: QButton(
                    label: saving ? 'Menyimpan...' : 'Simpan',
                    enabled: !saving,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSection(BuildContext context, AppColors colors) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Bukti Struk / Foto Transaksi',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (!hasImage) ...[
          if (ReceiptOcrService.isSupported)
            InkWell(
              onTap: scanning ? null : _scanReceipt,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3), width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                      child: scanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.document_scanner_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scanning ? 'Memindai struk...' : 'Pindai Struk (OCR)',
                          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          'Potret struk, jumlah & tanggal terisi otomatis',
                          style: TextStyle(color: colors.textTertiary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: colors.border,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_a_photo_outlined, color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lampirkan Foto Struk / Nota',
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        'Klik untuk memilih gambar dari galeri/berkas',
                        style: TextStyle(color: colors.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3), width: 1.2),
            ),
            child: Row(
              children: [
                // Image Thumbnail
                GestureDetector(
                  onTap: () => ReceiptPreviewDialog.show(
                    context,
                    imagePath: imagePath!,
                    title: 'Pratinjau Struk',
                    subtitle: memo.isNotEmpty ? memo : 'Transaksi ${type.name}',
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Image.file(
                          File(imagePath!),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: colors.border,
                            child: Icon(Icons.image_not_supported_rounded, color: colors.textTertiary),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Details & View Action
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Foto struk terlampir',
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => ReceiptPreviewDialog.show(
                          context,
                          imagePath: imagePath!,
                          title: 'Pratinjau Struk',
                          subtitle: memo.isNotEmpty ? memo : 'Transaksi ${type.name}',
                        ),
                        child: Text(
                          'Ketuk untuk lihat penuh',
                          style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                // Change & Remove buttons
                IconButton(
                  tooltip: 'Ganti gambar',
                  icon: Icon(Icons.refresh_rounded, color: colors.textSecondary, size: 20),
                  onPressed: _pickImage,
                ),
                IconButton(
                  tooltip: 'Hapus lampiran',
                  icon: Icon(Icons.delete_outline_rounded, color: colors.danger, size: 20),
                  onPressed: () => setState(() {
                    imagePath = null;
                    isNewImagePicked = false;
                  }),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picked = await _receipts.pickReceiptImage();
    if (picked != null) {
      setState(() {
        imagePath = picked;
        isNewImagePicked = true;
      });
    }
  }

  Future<void> _scanReceipt() async {
    final photoPath = await _ocr.captureFromCamera();
    if (photoPath == null || !mounted) return;

    setState(() => scanning = true);
    final result = await _ocr.scan(photoPath);
    if (!mounted) return;
    setState(() => scanning = false);

    if (result == null || !result.hasAnything) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada teks yang terbaca dari struk ini. Coba foto ulang lebih terang/lurus, atau lampirkan manual.')),
      );
      // Still attach the photo — it's useful as proof even without a
      // successful auto-read.
      setState(() {
        imagePath = photoPath;
        isNewImagePicked = true;
      });
      return;
    }

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReceiptScanReviewSheet(result: result),
    );

    setState(() {
      imagePath = photoPath;
      isNewImagePicked = true;
      if (applied == true) {
        if (result.amount != null) amount = result.amount!;
        if (result.date != null) {
          date = result.date!;
        }
        if ((memo.trim().isEmpty) && result.merchant != null) {
          memo = result.merchant!;
        }
      }
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus transaksi ini?'),
        content: const Text('Saldo akun terkait akan disesuaikan kembali dan struk yang terlampir akan dibersihkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => saving = true);
    await _ledger.delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _submit() async {
    if (accountId == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi akun dan jumlah terlebih dahulu')),
      );
      return;
    }
    if (type == TxType.transfer && (toAccountId == null || toAccountId == accountId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun tujuan transfer yang berbeda')),
      );
      return;
    }
    setState(() => saving = true);

    // Save image permanently if freshly picked
    String? finalImagePath = imagePath;
    if (isNewImagePicked && imagePath != null) {
      try {
        finalImagePath = await _receipts.saveReceiptPermanently(imagePath!);
      } catch (_) {
        finalImagePath = imagePath;
      }
    }

    if (isEditing) {
      final updated = widget.existing!
        ..type = type
        ..amount = amount
        ..accountId = accountId!
        ..toAccountId = type == TxType.transfer ? toAccountId : null
        ..categoryId = type == TxType.transfer ? null : categoryId
        ..date = _combinedDateTime
        ..memo = memo.trim().isEmpty ? null : memo.trim()
        ..imagePath = finalImagePath;
      await _ledger.update(updated);
    } else if (type == TxType.income) {
      await _ledger.addIncome(
        accountId: accountId!,
        categoryId: categoryId ?? '',
        amount: amount,
        date: _combinedDateTime,
        memo: memo.trim().isEmpty ? null : memo.trim(),
        imagePath: finalImagePath,
      );
    } else if (type == TxType.expense) {
      await _ledger.addExpense(
        accountId: accountId!,
        categoryId: categoryId ?? '',
        amount: amount,
        date: _combinedDateTime,
        memo: memo.trim().isEmpty ? null : memo.trim(),
        imagePath: finalImagePath,
      );
    } else {
      await _ledger.addTransfer(
        fromAccountId: accountId!,
        toAccountId: toAccountId!,
        amount: amount,
        date: _combinedDateTime,
        memo: memo.trim().isEmpty ? null : memo.trim(),
        imagePath: finalImagePath,
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Shows the OCR's best-guess amount/date/merchant and the raw recognized
/// text, and lets the user apply it to the form or dismiss it — the scan
/// never silently overwrites what's on screen.
class _ReceiptScanReviewSheet extends StatefulWidget {
  const _ReceiptScanReviewSheet({required this.result});
  final ReceiptScanResult result;

  @override
  State<_ReceiptScanReviewSheet> createState() => _ReceiptScanReviewSheetState();
}

class _ReceiptScanReviewSheetState extends State<_ReceiptScanReviewSheet> {
  bool showRawText = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final r = widget.result;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.document_scanner_outlined, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Hasil pindai struk', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Periksa dulu sebelum diterapkan — pembacaan otomatis bisa saja meleset.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (r.amount != null)
              _ReviewRow(icon: Icons.payments_outlined, label: 'Jumlah terdeteksi', value: r.amount!.rupiah),
            if (r.date != null)
              _ReviewRow(
                icon: Icons.event_outlined,
                label: 'Tanggal terdeteksi',
                value: DateFormat('d MMM y', 'id_ID').format(r.date!),
              ),
            if (r.merchant != null && r.merchant!.isNotEmpty)
              _ReviewRow(icon: Icons.storefront_outlined, label: 'Nama toko terdeteksi', value: r.merchant!),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => setState(() => showRawText = !showRawText),
              icon: Icon(showRawText ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              label: Text(showRawText ? 'Sembunyikan teks mentah' : 'Lihat teks mentah hasil pindai'),
            ),
            if (showRawText)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text(r.rawText, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: QOutlineButton(
                    label: 'Isi manual saja',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: QButton(
                    label: 'Terapkan ke form',
                    onPressed: () => Navigator.of(context).pop(true),
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

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

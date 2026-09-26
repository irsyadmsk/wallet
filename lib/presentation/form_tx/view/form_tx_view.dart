import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/data/services/currency/currency_service.dart';
import 'package:financial_recording/data/services/currency/currency.dart';
import 'package:financial_recording/core.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/category_suggester.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/data/services/receipt_ocr_service.dart';
import 'package:financial_recording/data/services/receipt_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/form/amount_field.dart';
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
    this.initialAmount,
    this.initialCategoryId,
  });

  final TxModel? existing;
  final TxType initialType;

  /// Pre-fills the source account (or "dari akun" for a transfer) on a new
  /// transaction — e.g. opening the form to pay off a specific card.
  final String? initialAccountId;

  /// Pre-fills the destination account of a new transfer.
  final String? initialToAccountId;
  final String? initialMemo;

  /// Pre-fills a new transaction, e.g. "Catat zakat" from the zakat tool.
  final int? initialAmount;
  final String? initialCategoryId;

  @override
  State<FormTxView> createState() => _FormTxViewState();
}

class _FormTxViewState extends State<FormTxView> {
  final _accounts = AccountRepository();
  final _categories = TxCategoryRepository();
  final _txs = TxRepository();
  final _ledger = LedgerService();
  final _receipts = ReceiptService();
  final _ocr = ReceiptOcrService();
  bool scanning = false;
  List<TxModel> _memoSuggestions = [];

  late TxType type = widget.existing?.type ?? widget.initialType;
  late String? accountId =
      widget.existing?.accountId ?? widget.initialAccountId ?? _accounts.all().firstOrNull?.id;
  late String? toAccountId = widget.existing?.toAccountId ?? widget.initialToAccountId;
  late String? categoryId = widget.existing?.categoryId ?? widget.initialCategoryId;
  late int amount = widget.existing?.amount ?? widget.initialAmount ?? 0;

  /// Once the user picks a category by hand, stop auto-suggesting one.
  bool _categoryTouched = false;
  bool _categoryAuto = false;
  late DateTime date = widget.existing?.date ?? DateTime.now();
  late TimeOfDay time = TimeOfDay.fromDateTime(widget.existing?.date ?? DateTime.now());
  late String memo = widget.existing?.memo ?? widget.initialMemo ?? '';
  late String? imagePath = widget.existing?.imagePath;
  late int transferFee = widget.existing?.transferFee ?? 0;

  /// Received amount of a transfer between two currencies; follows the
  /// live rate until the user types their own (the bank's actual rate).
  late int? toAmount = widget.existing?.toAmount;
  late bool _toAmountTouched = widget.existing?.toAmount != null;
  final _fx = CurrencyService.instance;
  String get _fromCur => accountId == null ? Currency.idr : _fx.currencyOf(accountId!);
  String get _toCur => toAccountId == null ? _fromCur : _fx.currencyOf(toAccountId!);
  bool get _crossCurrency => type == TxType.transfer && toAccountId != null && _fromCur != _toCur;
  int get _received => _toAmountTouched && toAmount != null ? toAmount! : _fx.convert(amount, _fromCur, _toCur);
  int installments = 1;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
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
                      ButtonSegment(value: TxType.expense, label: Text('Pengeluaran', maxLines: 1, softWrap: false)),
                      ButtonSegment(value: TxType.income, label: Text('Pemasukan', maxLines: 1, softWrap: false)),
                      ButtonSegment(value: TxType.transfer, label: Text('Transfer', maxLines: 1, softWrap: false)),
                    ],
                    selected: {type},
                    onSelectionChanged: (s) => setState(() {
                      type = s.first;
                      categoryId = null;
                    }),
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  AmountField(
                    label: 'Jumlah',
                    currency: _fromCur,
                    value: amount,
                    large: true,
                    // New entries open straight into the amount with the keyboard up.
                    autofocus: !isEditing && amount == 0,
                    accent: switch (type) {
                      TxType.expense => colors.expense,
                      TxType.income => colors.income,
                      TxType.transfer => colors.transfer,
                    },
                    onChanged: (v) => setState(() => amount = v),
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
                      onChanged: (v, _) => setState(() {
                        categoryId = v as String?;
                        _categoryTouched = true;
                        _categoryAuto = false;
                      }),
                    ),

                  if (_crossCurrency)
                    AmountField(
                      label: 'Diterima di akun tujuan',
                      currency: _toCur,
                      value: _received,
                      showQuickChips: false,
                      helper: _rateHint(),
                      onChanged: (v) => setState(() {
                        toAmount = v;
                        _toAmountTouched = true;
                      }),
                    ),

                  if (type == TxType.transfer)
                    AmountField(
                      currency: _fromCur,
                      label: 'Biaya transfer (opsional)',
                      value: transferFee,
                      showCalculator: false,
                      helper: 'Akun tujuan tetap menerima jumlah penuh',
                      onChanged: (v) => transferFee = v,
                    ),

                  if (type == TxType.expense && !isEditing)
                    QDropdownField(
                      label: 'Jumlah cicilan',
                      value: installments,
                      items: [
                        {'value': 1, 'label': 'Tidak dicicil'},
                        for (final n in [2, 3, 6, 9, 12]) {'value': n, 'label': '$n bulan'},
                      ],
                      onChanged: (v, _) => setState(() => installments = v as int? ?? 1),
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
                    onChanged: _onMemoChanged,
                    maxLines: 2,
                  ),
                  if (_categoryAuto && categoryId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 14, color: colors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Kategori dipilih otomatis dari riwayat: ${_categories.pathName(categoryId!)}',
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isEditing && _memoSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final s in _memoSuggestions)
                          ActionChip(
                            avatar: const Icon(Icons.history_rounded, size: 16),
                            label: Text(s.memo ?? ''),
                            onPressed: () => _applyMemoSuggestion(s),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),

                  // Receipt attachment section
                  _buildReceiptSection(context, colors),

                ],
              ),
            ),
          ),
          // While typing further down (catatan, jam), the amount and type
          // scroll out of sight under the keyboard; keep them readable here.
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: isKeyboardUp(context) && amount > 0 ? _summary(colors) : const SizedBox(width: double.infinity),
          ),
          // Pinned under the scrolling fields so "Simpan" is always one tap
          // away — also while the keyboard is up.
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border))),
            child: Row(
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
                    label: saving ? 'Menyimpan…' : 'Simpan',
                    enabled: !saving,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(AppColors colors) {
    final (label, color) = switch (type) {
      TxType.expense => ('Pengeluaran', colors.expense),
      TxType.income => ('Pemasukan', colors.income),
      TxType.transfer => ('Transfer', colors.transfer),
    };
    final where = type == TxType.transfer
        ? [_accounts.byId(accountId ?? '')?.name, _accounts.byId(toAccountId ?? '')?.name].whereType<String>().join(' → ')
        : [categoryId == null ? null : _categories.byId(categoryId!)?.name, _accounts.byId(accountId ?? '')?.name]
            .whereType<String>()
            .join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 8, AppSpacing.lg, 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), border: Border(top: BorderSide(color: colors.border))),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12.5)),
          const SizedBox(width: 8),
          Text(amount.money(_fromCur), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(where, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  /// "1 USD = Rp 17.909" for the pair being transferred, or a note that no
  /// rate is known yet.
  String _rateHint() {
    final foreign = _fromCur == Currency.idr ? _toCur : _fromCur;
    final r = _fx.rate(foreign);
    if (r == null) return 'Kurs belum tersedia — isi jumlah yang diterima';
    final c = Currency.of(foreign);
    return c.isGold ? 'Buyback emas: ${r.round().rupiah}/gram' : 'Kurs: 1 ${c.code} = ${r.round().rupiah}';
  }

  Widget _buildReceiptSection(BuildContext context, AppColors colors) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    // Optional, so it stays one compact row until a photo is attached.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasImage)
          Row(
            children: [
              if (ReceiptOcrService.isSupported) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: scanning ? null : _scanReceipt,
                    icon: scanning
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.document_scanner_outlined, size: 18),
                    label: Text(scanning ? 'Memindai…' : 'Pindai struk', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: const Text('Lampirkan foto', maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          )
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

  /// Suggests up to 3 past transactions whose memo contains what's typed so
  /// far — tapping one refills memo + category + amount + account, matching
  /// the "autofill riwayat" convenience from Money Manager. Only offered
  /// while adding a new transaction, never while editing an existing one.
  void _onMemoChanged(String v) {
    memo = v;
    if (!isEditing && !_categoryTouched && type != TxType.transfer) {
      final guess = CategorySuggester.suggest(v, type, _txs.all());
      if (guess != null && guess != categoryId && _categories.byId(guess) != null) {
        setState(() {
          categoryId = guess;
          _categoryAuto = true;
        });
      }
    }
    final query = v.trim().toLowerCase();
    if (isEditing || query.length < 2) {
      if (_memoSuggestions.isNotEmpty) setState(() => _memoSuggestions = []);
      return;
    }
    final seen = <String>{};
    final matches = <TxModel>[];
    final all = _txs.all()..sort((a, b) => b.date.compareTo(a.date));
    for (final t in all) {
      final m = t.memo;
      if (m == null || m.isEmpty || t.type != type) continue;
      final key = m.toLowerCase();
      if (!key.contains(query) || seen.contains(key)) continue;
      seen.add(key);
      matches.add(t);
      if (matches.length >= 3) break;
    }
    setState(() => _memoSuggestions = matches);
  }

  void _applyMemoSuggestion(TxModel s) {
    setState(() {
      memo = s.memo ?? '';
      amount = s.amount;
      accountId = s.accountId;
      categoryId = s.categoryId;
      _memoSuggestions = [];
    });
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
        ..imagePath = finalImagePath
        ..transferFee = type == TxType.transfer && transferFee > 0 ? transferFee : null
        ..toAmount = _crossCurrency ? _received : null;
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
      if (installments > 1) {
        await _addInstallments(finalImagePath);
      } else {
        await _ledger.addExpense(
          accountId: accountId!,
          categoryId: categoryId ?? '',
          amount: amount,
          date: _combinedDateTime,
          memo: memo.trim().isEmpty ? null : memo.trim(),
          imagePath: finalImagePath,
        );
      }
    } else {
      await _ledger.addTransfer(
        fromAccountId: accountId!,
        toAccountId: toAccountId!,
        amount: amount,
        date: _combinedDateTime,
        memo: memo.trim().isEmpty ? null : memo.trim(),
        imagePath: finalImagePath,
        fee: transferFee > 0 ? transferFee : null,
        toAmount: _crossCurrency ? _received : null,
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  /// Splits a purchase into [installments] monthly expenses of amount ÷ n
  /// each (remainder folded into the first one), same day-of-month going
  /// forward — a lightweight "cicilan" without needing the recurring-rule
  /// machinery, since the count is fixed and known up front.
  Future<void> _addInstallments(String? imagePath) async {
    final base = amount ~/ installments;
    final remainder = amount - base * installments;
    final baseMemo = memo.trim();
    for (var i = 0; i < installments; i++) {
      final installmentAmount = base + (i == 0 ? remainder : 0);
      final installmentDate = DateTime(
        _combinedDateTime.year,
        _combinedDateTime.month + i,
        _combinedDateTime.day,
        _combinedDateTime.hour,
        _combinedDateTime.minute,
      );
      final suffix = '(${i + 1}/$installments)';
      await _ledger.addExpense(
        accountId: accountId!,
        categoryId: categoryId ?? '',
        amount: installmentAmount,
        date: installmentDate,
        memo: baseMemo.isEmpty ? suffix : '$baseMemo $suffix',
        imagePath: i == 0 ? imagePath : null,
      );
    }
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:financial_recording/data/models/crypto_model/crypto_holding_model.dart';
import 'package:financial_recording/data/services/crypto_portfolio.dart';
import 'package:financial_recording/data/services/crypto_price_service.dart';
import 'package:financial_recording/presentation/crypto/controller/crypto_controller.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/util/money/money_format.dart';
import 'package:financial_recording/util/thousands_formatter/thousands_formatter.dart';

final _amountFmt = NumberFormat('#,##0.########', 'id_ID');
final _pctFmt = NumberFormat('#,##0.0#', 'id_ID');
final _timeFmt = DateFormat('d MMM, HH.mm', 'id_ID');

/// Coin prices span from fractions of a rupiah to billions, so the number
/// of decimals follows the magnitude.
String _price(double idr) {
  final digits = idr >= 1000 ? 0 : (idr >= 1 ? 2 : 6);
  return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: digits).format(idr);
}

String _pct(double v) => '${v >= 0 ? '+' : ''}${_pctFmt.format(v)}%';

/// Crypto portfolio: coins held, valued at live rupiah prices from
/// CoinGecko. Record-keeping only — no trading and no advice.
class CryptoView extends StatelessWidget {
  const CryptoView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CryptoController(), tag: 'crypto');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Kripto'),
        actions: [
          Obx(() => IconButton(
                tooltip: 'Perbarui harga',
                onPressed: c.loadingPrices.value ? null : () => c.refreshPrices(force: true),
                icon: c.loadingPrices.value
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded),
              )),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: FilledButton.tonalIcon(
              onPressed: () => _openEditor(context, c, null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => c.refreshPrices(force: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ContentShell(
            child: Obx(() {
              final s = c.summary.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryCard(summary: s, controller: c),
                  const SizedBox(height: AppSpacing.lg),
                  if (s.holdings.isEmpty)
                    _EmptyState(onAdd: () => _openEditor(context, c, null))
                  else
                    Card(
                      child: Column(
                        children: [
                          for (var i = 0; i < s.holdings.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _HoldingRow(value: s.holdings[i], controller: c),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Hanya untuk pencatatan. Harga dari CoinGecko dan bisa terlambat beberapa menit; '
                    'bukan saran investasi. Nilai kripto belum dihitung dalam kekayaan bersih.',
                    style: TextStyle(fontSize: 11, color: context.colors.textTertiary),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

Future<void> _openEditor(BuildContext context, CryptoController c, CryptoHoldingModel? existing) {
  return showAdaptiveSheet<void>(context, builder: (_) => _HoldingEditor(controller: c, existing: existing));
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.controller});
  final PortfolioSummary summary;
  final CryptoController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final change = summary.change24hPercent;
    final gainPct = summary.totalGainPercent;
    final error = controller.priceError.value;
    final at = controller.pricesAt.value;

    Widget stat(String label, String value, String? sub, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: AppTypography.numeric(size: 15, weight: FontWeight.w600, color: color)),
              if (sub != null) Text(sub, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nilai portofolio', style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              summary.totalValue.rupiah,
              style: AppTypography.numeric(size: 30, weight: FontWeight.w600, color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                stat(
                  '24 jam',
                  summary.change24hValue.signedRupiah,
                  change == null ? null : _pct(change),
                  summary.change24hValue >= 0 ? colors.income : colors.expense,
                ),
                stat(
                  'Untung / rugi',
                  gainPct == null ? '—' : summary.totalGain.signedRupiah,
                  gainPct == null ? 'Isi total modal untuk melihat' : _pct(gainPct),
                  gainPct == null ? colors.textSecondary : (summary.totalGain >= 0 ? colors.income : colors.expense),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              error ?? (at == null ? 'Harga belum dimuat' : 'Harga CoinGecko · ${_timeFmt.format(at)}'),
              style: TextStyle(fontSize: 11, color: error == null ? colors.textTertiary : colors.warning),
            ),
            if (summary.unpriced > 0)
              Text(
                '${summary.unpriced} koin belum punya harga dan belum dihitung.',
                style: TextStyle(fontSize: 11, color: colors.warning),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.currency_bitcoin_rounded, size: 40, color: colors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          const Text('Belum ada koin', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Catat koin yang Anda miliki — nilainya dihitung otomatis dari harga terkini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Tambah koin')),
        ],
      ),
    );
  }
}

enum _RowAction { edit, delete }

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({required this.value, required this.controller});
  final HoldingValue value;
  final CryptoController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final h = value.holding;
    final price = value.price;
    final v = value.value;
    final change = price?.change24h;
    final gainPct = value.gainPercent;

    return InkWell(
      onTap: () => _openEditor(context, controller, h),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.xs, AppSpacing.md),
        child: Row(
          children: [
            CoinAvatar(imageUrl: h.imageUrl, symbol: h.symbol),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${_amountFmt.format(h.amount)} ${h.symbol}${price == null ? '' : ' · ${_price(price.idr)}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  v == null ? '—' : v.rupiah,
                  style: AppTypography.numeric(size: 14, weight: FontWeight.w600, color: colors.textPrimary),
                ),
                const SizedBox(height: 2),
                // Each figure in its own colour: the 24h move and the
                // overall gain often point in different directions.
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 11),
                    children: [
                      if (change != null)
                        TextSpan(text: '24j ${_pct(change)}', style: TextStyle(color: change >= 0 ? colors.income : colors.expense)),
                      if (change != null && gainPct != null)
                        TextSpan(text: ' · ', style: TextStyle(color: colors.textTertiary)),
                      if (gainPct != null)
                        TextSpan(text: 'P/L ${_pct(gainPct)}', style: TextStyle(color: gainPct >= 0 ? colors.income : colors.expense)),
                    ],
                  ),
                ),
              ],
            ),
            PopupMenuButton<_RowAction>(
              tooltip: 'Opsi ${h.name}',
              icon: Icon(Icons.more_vert_rounded, size: 20, color: colors.textSecondary),
              onSelected: (a) async {
                switch (a) {
                  case _RowAction.edit:
                    await _openEditor(context, controller, h);
                  case _RowAction.delete:
                    if (await _confirmDelete(context, h)) await controller.delete(h.id);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _RowAction.edit,
                  child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Ubah'), contentPadding: EdgeInsets.zero),
                ),
                PopupMenuItem(
                  value: _RowAction.delete,
                  child: ListTile(leading: Icon(Icons.delete_outline_rounded), title: Text('Hapus'), contentPadding: EdgeInsets.zero),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, CryptoHoldingModel h) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Hapus ${h.name}?'),
      content: const Text('Catatan koin ini dihapus dari portofolio di semua perangkat.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ctx.colors.danger),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Coin logo, falling back to the ticker's first letter when there is no
/// image or it fails to load (offline).
class CoinAvatar extends StatelessWidget {
  const CoinAvatar({super.key, this.imageUrl, required this.symbol, this.size = 36});
  final String? imageUrl;
  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.primaryContainer,
      child: Text(
        symbol.isEmpty ? '?' : symbol.characters.first,
        style: TextStyle(fontWeight: FontWeight.w700, color: colors.primary, fontSize: size * 0.4),
      ),
    );
    final url = imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

/// Add or edit one holding. Adding a coin that's already in the portfolio
/// tops up that holding (amount and cost are added) instead of creating a
/// second row for the same coin.
class _HoldingEditor extends StatefulWidget {
  const _HoldingEditor({required this.controller, this.existing});
  final CryptoController controller;
  final CryptoHoldingModel? existing;

  @override
  State<_HoldingEditor> createState() => _HoldingEditorState();
}

class _HoldingEditorState extends State<_HoldingEditor> {
  late CoinSearchResult? _coin = widget.existing == null
      ? null
      : CoinSearchResult(
          id: widget.existing!.coinId,
          symbol: widget.existing!.symbol,
          name: widget.existing!.name,
          thumb: widget.existing!.imageUrl,
        );
  late final _amount = TextEditingController(
    text: widget.existing == null ? '' : _amountFmt.format(widget.existing!.amount),
  );
  late final _cost = TextEditingController(
    text: (widget.existing?.costBasis ?? 0) > 0 ? NumberFormat('#,###', 'id_ID').format(widget.existing!.costBasis) : '',
  );
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  final _query = TextEditingController();

  Timer? _debounce;
  List<CoinSearchResult> _results = [];
  bool _searching = false;
  String? _searchError;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_amount, _cost, _note, _query]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final r = await widget.controller.priceService.search(q);
      if (mounted && _query.text == q) setState(() => _results = r);
    } on CryptoPriceException catch (e) {
      if (mounted) setState(() => _searchError = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  /// Accepts both "0,5" and "0.5"; dots before a comma are thousands
  /// separators ("1.250,5").
  static double? _parseAmount(String raw) {
    var s = raw.trim().replaceAll(' ', '');
    if (s.isEmpty) return null;
    if (s.contains(',')) s = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s);
  }

  Future<void> _save() async {
    final coin = _coin;
    final amount = _parseAmount(_amount.text);
    final cost = int.tryParse(_cost.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    String? problem;
    if (coin == null) problem = 'Pilih koin terlebih dahulu.';
    if (problem == null && (amount == null || amount <= 0)) problem = 'Jumlah koin harus lebih dari 0.';
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();

    final CryptoHoldingModel holding;
    if (_isEditing) {
      holding = widget.existing!
        ..amount = amount!
        ..costBasis = cost
        ..note = note;
    } else {
      final existing = widget.controller.existingFor(coin!.id);
      holding = existing != null
          ? (existing
            ..amount = existing.amount + amount!
            ..costBasis = existing.costBasis + cost
            ..note = note ?? existing.note)
          : CryptoHoldingModel(
              id: const Uuid().v4(),
              coinId: coin.id,
              symbol: coin.symbol,
              name: coin.name,
              imageUrl: coin.thumb,
              amount: amount!,
              costBasis: cost,
              note: note,
            );
    }
    await widget.controller.save(holding);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final coin = _coin;
    final alreadyHeld = !_isEditing && coin != null && widget.controller.existingFor(coin.id) != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isEditing ? 'Ubah koin' : 'Tambah koin', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            if (coin == null) ...[
              TextField(
                controller: _query,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Cari koin',
                  hintText: 'mis. Bitcoin, ETH, Solana',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
                onChanged: _onQuery,
              ),
              if (_searchError != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(_searchError!, style: TextStyle(color: colors.warning, fontSize: 12)),
                ),
              for (final r in _results.take(8))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CoinAvatar(imageUrl: r.thumb, symbol: r.symbol, size: 32),
                  title: Text(r.name),
                  subtitle: Text(r.symbol),
                  trailing: r.rank == null ? null : Text('#${r.rank}', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                  onTap: () => setState(() {
                    _coin = r;
                    _results = [];
                  }),
                ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    CoinAvatar(imageUrl: coin.thumb, symbol: coin.symbol, size: 32),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text('${coin.name} (${coin.symbol})', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    if (!_isEditing) TextButton(onPressed: () => setState(() => _coin = null), child: const Text('Ganti')),
                  ],
                ),
              ),
              if (alreadyHeld)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'Koin ini sudah ada di portofolio — jumlah dan modal di bawah akan ditambahkan ke catatan yang ada.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _amount,
                autofocus: !_isEditing,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(labelText: 'Jumlah koin', hintText: 'mis. 0,0125', suffixText: coin.symbol),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _cost,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Total modal (opsional)',
                  prefixText: 'Rp ',
                  helperText: 'Total rupiah yang Anda bayar, untuk menghitung untung/rugi.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Catatan (opsional)', hintText: 'mis. disimpan di Indodax'),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  if (_isEditing) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: colors.danger),
                        onPressed: () async {
                          if (!await _confirmDelete(context, widget.existing!)) return;
                          await widget.controller.delete(widget.existing!.id);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Hapus'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(flex: 2, child: FilledButton(onPressed: _save, child: const Text('Simpan'))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

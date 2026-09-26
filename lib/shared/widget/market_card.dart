import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/app/app_events.dart';
import 'package:financial_recording/data/services/currency/currency.dart';
import 'package:financial_recording/data/services/currency/currency_service.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/util/money/money_format.dart';

/// Today's gold price per gram and the exchange rates of the currencies
/// the user holds (USD always, as the reference) — the numbers behind the
/// rupiah total.
class MarketCard extends StatefulWidget {
  const MarketCard({super.key, this.compact = false});

  /// One-line strip for the dashboard instead of the full card.
  final bool compact;

  @override
  State<MarketCard> createState() => _MarketCardState();
}

class _MarketCardState extends State<MarketCard> {
  final _fx = CurrencyService.instance;
  bool _loading = false;

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final ok = await _fx.refresh(force: true);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      notifyDataChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui kurs. Memakai data terakhir yang tersimpan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _fx.version,
      builder: (context, _, _) => widget.compact ? _strip(context) : _card(context),
    );
  }

  List<String> get _codes {
    final held = _fx.heldCurrencies()..remove(Currency.gold);
    return ['USD', ...held.where((c) => c != 'USD')];
  }

  Widget _strip(BuildContext context) {
    final c = context.colors;
    final gold = _fx.gold;
    final items = <String>[
      if (gold != null) '🥇 Emas ${gold.buyback.rupiah}/g',
      for (final code in _codes)
        if (_fx.rate(code) != null) '${Currency.of(code).flag} 1 $code = ${_fx.rate(code)!.round().rupiah}',
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Text(
      items.join('  ·  '),
      style: TextStyle(fontSize: 12.5, color: c.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _card(BuildContext context) {
    final c = context.colors;
    final gold = _fx.gold;
    final at = _fx.updatedAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Harga hari ini', style: Theme.of(context).textTheme.titleMedium)),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  IconButton(tooltip: 'Perbarui kurs & harga emas', icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
              ],
            ),
            if (gold != null) ...[
              _Row(
                leading: '🥇',
                label: 'Emas per gram',
                sub: gold.source,
                value: gold.sell.rupiah,
                valueSub: 'buyback ${gold.buyback.rupiah}',
              ),
            ],
            for (final code in _codes)
              if (_fx.rate(code) != null)
                _Row(
                  leading: Currency.of(code).flag,
                  label: '1 ${Currency.of(code).code}',
                  sub: Currency.of(code).name,
                  value: _fx.rate(code)!.round().rupiah,
                ),
            if (gold == null && _fx.rate('USD') == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Belum ada data. Ketuk ↻ saat online.', style: TextStyle(color: c.textSecondary)),
              ),
            if (at != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 8),
                child: Text(
                  'Diperbarui ${DateFormat('d MMM, HH.mm', 'id_ID').format(at)}. Emas dinilai dengan harga buyback.',
                  style: TextStyle(fontSize: 11.5, color: c.textTertiary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.leading, required this.label, required this.sub, required this.value, this.valueSub});
  final String leading;
  final String label;
  final String sub;
  final String value;
  final String? valueSub;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6, right: 8),
      child: Row(
        children: [
          Text(leading, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(sub, style: TextStyle(fontSize: 11.5, color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTypography.numeric(size: 14.5, weight: FontWeight.w600, color: c.textPrimary)),
              if (valueSub != null) Text(valueSub!, style: TextStyle(fontSize: 11.5, color: c.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

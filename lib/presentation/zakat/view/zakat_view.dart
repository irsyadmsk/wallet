import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/data/services/currency/currency_service.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/debt_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_query.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/zakat_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/presentation/form_tx/view/form_tx_view.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';
import 'package:financial_recording/util/money/money_format.dart';
import 'package:financial_recording/util/thousands_formatter/thousands_formatter.dart';

enum _Kind { income, wealth, fitrah }

/// Zakat calculator (penghasilan, mal, fitrah). Amounts are pre-filled
/// from the ledger — this month's income, current asset balances, debts
/// still owed — and the result can be recorded as an expense in one tap.
class ZakatView extends StatefulWidget {
  const ZakatView({super.key});

  @override
  State<ZakatView> createState() => _ZakatViewState();
}

class _ZakatViewState extends State<ZakatView> {
  _Kind _kind = _Kind.income;
  final _gold = TextEditingController();
  final _rice = TextEditingController();
  final _income = TextEditingController();
  final _assets = TextEditingController();
  final _extraAssets = TextEditingController();
  final _debts = TextEditingController();
  int _people = 1;
  bool _haul = true;

  static final _fmt = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final income = TxRepository()
        .query(TxQuery(from: DateTime(now.year, now.month, 1), to: DateTime(now.year, now.month + 1, 1), types: {TxType.income}))
        .fold(0, (s, t) => s + t.idr);
    _income.text = income > 0 ? _fmt.format(income) : '';
    final assets = AccountRepository().totalAssets;
    _assets.text = assets > 0 ? _fmt.format(assets) : '';
    final owed = DebtRepository().active().where((d) => !d.isLoan).fold(0, (s, d) => s + d.remainingAmount);
    _debts.text = owed > 0 ? _fmt.format(owed) : '';
    ZakatPrefs.load().then((v) {
      if (!mounted) return;
      setState(() {
        if (v.$1 != null) _gold.text = _fmt.format(v.$1);
        if (v.$2 != null) _rice.text = _fmt.format(v.$2);
      });
    });
    for (final c in [_gold, _rice, _income, _assets, _extraAssets, _debts]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_gold, _rice, _income, _assets, _extraAssets, _debts]) {
      c.dispose();
    }
    super.dispose();
  }

  int _n(TextEditingController c) => int.tryParse(c.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  (int amount, String? note) get _result {
    final gold = _n(_gold);
    switch (_kind) {
      case _Kind.income:
        if (gold <= 0) return (0, 'Isi harga emas per gram untuk menentukan nisab.');
        final z = Zakat.income(monthlyIncome: _n(_income), goldPricePerGram: gold);
        return (z, z == 0 ? 'Pemasukan bulan ini di bawah nisab bulanan ${Zakat.nisabMonthly(gold).rupiah}, belum wajib zakat.' : null);
      case _Kind.wealth:
        if (gold <= 0) return (0, 'Isi harga emas per gram untuk menentukan nisab.');
        final assets = _n(_assets) + _n(_extraAssets);
        final z = Zakat.wealth(assets: assets, debtsDue: _n(_debts), goldPricePerGram: gold, haulReached: _haul);
        if (z > 0) return (z, null);
        if (!_haul) return (0, 'Belum wajib: harta belum dimiliki genap satu tahun (haul).');
        return (0, 'Harta bersih di bawah nisab ${Zakat.nisabYearly(gold).rupiah}, belum wajib zakat.');
      case _Kind.fitrah:
        final rice = _n(_rice);
        if (rice <= 0) return (0, 'Isi harga beras per kg yang biasa Anda konsumsi.');
        return (Zakat.fitrah(people: _people, ricePricePerKg: rice), null);
    }
  }

  Future<void> _record(int amount) async {
    final label = switch (_kind) {
      _Kind.income => 'Zakat penghasilan',
      _Kind.wealth => 'Zakat mal',
      _Kind.fitrah => 'Zakat fitrah ($_people jiwa)',
    };
    final cats = TxCategoryRepository().byType(1);
    final zakatCat = cats.where((c) => c.name.toLowerCase().contains('zakat')).firstOrNull ??
        cats.where((c) => c.name.toLowerCase().contains('sedekah') || c.name.toLowerCase().contains('donasi')).firstOrNull;
    await showAdaptiveSheet<bool>(
      context,
      builder: (_) => FormTxView(initialMemo: label, initialAmount: amount, initialCategoryId: zakatCat?.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final (amount, note) = _result;
    final gold = _n(_gold);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Zakat')),
      body: SingleChildScrollView(
        child: ContentShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: PillTabs<_Kind>(
                  tabs: const [
                    PillTab(_Kind.income, 'Penghasilan', icon: Icons.work_outline_rounded),
                    PillTab(_Kind.wealth, 'Mal (harta)', icon: Icons.savings_outlined),
                    PillTab(_Kind.fitrah, 'Fitrah', icon: Icons.rice_bowl_outlined),
                  ],
                  value: _kind,
                  onChanged: (k) => setState(() => _kind = k),
                ),
              ),
              const SizedBox(height: 20),
              // Result, first — it's what the page is for.
              AnimatedContainer(
                duration: AppMotion.base,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: c.textPrimary, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      switch (_kind) {
                        _Kind.income => 'Zakat penghasilan bulan ini',
                        _Kind.wealth => 'Zakat mal tahun ini',
                        _Kind.fitrah => 'Zakat fitrah keluarga',
                      },
                      style: TextStyle(color: c.surfaceAlt.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 6),
                    AnimatedMoney(
                      value: amount,
                      style: AppTypography.display(size: 44, weight: FontWeight.w600, color: c.surfaceAlt),
                    ),
                    if (note != null) ...[
                      const SizedBox(height: 8),
                      Text(note, style: TextStyle(color: c.surfaceAlt.withValues(alpha: 0.75), height: 1.4)),
                    ],
                    const SizedBox(height: 16),
                    WButton(
                      label: 'Catat sebagai pengeluaran',
                      icon: Icons.add_rounded,
                      variant: WButtonVariant.inverse,
                      size: WButtonSize.small,
                      onPressed: amount > 0 ? () => _record(amount) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_kind != _Kind.fitrah) ...[
                        _MoneyField(
                          controller: _gold,
                          label: 'Harga emas per gram hari ini',
                          helper: gold > 0
                              ? 'Nisab 85 g = ${Zakat.nisabYearly(gold).rupiah} per tahun (${Zakat.nisabMonthly(gold).rupiah} per bulan)'
                              : 'Cek harga emas Antam terbaru, lalu isi di sini.',
                          onSaved: (v) => ZakatPrefs.save(gold: v),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (_kind == _Kind.income)
                        _MoneyField(controller: _income, label: 'Pemasukan bulan ini', helper: 'Terisi otomatis dari transaksi pemasukan bulan ini.'),
                      if (_kind == _Kind.wealth) ...[
                        _MoneyField(controller: _assets, label: 'Saldo tabungan & rekening', helper: 'Terisi otomatis dari total saldo aset Anda.'),
                        const SizedBox(height: 14),
                        _MoneyField(controller: _extraAssets, label: 'Emas, saham, piutang lancar (opsional)'),
                        const SizedBox(height: 14),
                        _MoneyField(controller: _debts, label: 'Utang jatuh tempo', helper: 'Terisi otomatis dari menu Utang & Piutang.'),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _haul,
                          onChanged: (v) => setState(() => _haul = v),
                          title: const Text('Sudah dimiliki genap satu tahun (haul)'),
                        ),
                      ],
                      if (_kind == _Kind.fitrah) ...[
                        _MoneyField(
                          controller: _rice,
                          label: 'Harga beras per kg',
                          helper: '2,5 kg per jiwa. Boleh juga mengikuti nominal yang ditetapkan BAZNAS daerah Anda.',
                          onSaved: (v) => ZakatPrefs.save(rice: v),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Text('Jumlah jiwa')),
                            WIconButton(
                              icon: Icons.remove_rounded,
                              tooltip: 'Kurangi jiwa',
                              filled: true,
                              onPressed: _people > 1 ? () => setState(() => _people--) : null,
                            ),
                            SizedBox(
                              width: 48,
                              child: Text('$_people',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.numeric(size: 20, weight: FontWeight.w600, color: c.textPrimary)),
                            ),
                            WIconButton(
                              icon: Icons.add_rounded,
                              tooltip: 'Tambah jiwa',
                              filled: true,
                              onPressed: _people < 30 ? () => setState(() => _people++) : null,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Dasar hukum', style: t.titleMedium),
              const SizedBox(height: 8),
              Text(
                '• UU No. 23 Tahun 2011 tentang Pengelolaan Zakat — Pasal 22: zakat yang dibayarkan melalui BAZNAS atau LAZ '
                'dikurangkan dari penghasilan kena pajak. Simpan bukti setor untuk SPT Tahunan.\n'
                '• Peraturan Menteri Agama No. 52 Tahun 2014 sebagaimana diubah dengan PMA No. 31 Tahun 2019 tentang syarat dan '
                'tata cara penghitungan zakat mal dan zakat fitrah: kadar zakat mal dan penghasilan 2,5%.\n'
                '• Nisab setara 85 gram emas mengikuti standar yang dipakai BAZNAS. Hasil di sini adalah perkiraan; '
                'untuk kasus khusus konsultasikan dengan amil atau BAZNAS setempat.',
                style: TextStyle(color: c.textSecondary, height: 1.55, fontSize: 13.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.controller, required this.label, this.helper, this.onSaved});
  final TextEditingController controller;
  final String label;
  final String? helper;
  final ValueChanged<int>? onSaved;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [ThousandsFormatter()],
      style: AppTypography.numeric(size: 16, weight: FontWeight.w500, color: context.colors.textPrimary),
      decoration: InputDecoration(labelText: label, prefixText: 'Rp ', helperText: helper, helperMaxLines: 2),
      onChanged: onSaved == null
          ? null
          : (v) {
              final n = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
              if (n != null) onSaved!(n);
            },
    );
  }
}

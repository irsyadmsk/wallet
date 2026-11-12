import 'package:flutter/material.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';

class PlanItemEdit {
  final AllocationItem? item;
  final bool delete;
  const PlanItemEdit(this.item, {this.delete = false});
}

class PlanItemSheet extends StatefulWidget {
  const PlanItemSheet({super.key, this.item, required this.group,
    required this.fx, this.allowRules = true, this.allowActual = true});
  final AllocationItem? item;
  final String group;
  final int fx;
  final bool allowRules, allowActual;
  @override
  State<PlanItemSheet> createState() => _PlanItemSheetState();
}

class _PlanItemSheetState extends State<PlanItemSheet> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  late String kind, currency;
  late bool included, enabled, rollover;
  late int months;
  TextEditingController field(String key) => fields[key]!;
  @override
  void initState() {
    super.initState();
    final item = widget.item, rule = item?.rule;
    kind = rule?.kind ?? 'fixed';
    currency = rule?.currency ?? 'IDR';
    months = rule?.months ?? 1;
    included = rule?.taxIncluded ?? false;
    enabled = rule?.enabled ?? true;
    rollover = item?.rollover ?? false;
    final values = <String, String>{
      'name': item?.name ?? '', 'group': item?.group ?? widget.group,
      'amount': '${item?.amount ?? 0}', 'note': item?.note ?? '',
      'price': currency == 'USD' ? ((rule?.price ?? 0) / 100).toStringAsFixed(2)
          : '${rule?.price ?? 0}',
      'tax': ((rule?.taxBps ?? 0) / 100).toString(),
      'target': '${rule?.target ?? 0}', 'weight': '${rule?.weight ?? 0}',
      'priority': '${rule?.priority ?? 1}',
      'actual': item?.actual?.toString() ?? '',
      'opening': '${item?.opening ?? 0}', 'spent': '${item?.spent ?? 0}',
    };
    for (final e in values.entries) { fields[e.key] = TextEditingController(text: e.value); }
  }
  @override
  void dispose() {
    for (final c in fields.values) { c.dispose(); }
    super.dispose();
  }
  String? whole(String? v, {int max = 1000000000000, bool signed = false}) {
    final n = int.tryParse(v ?? '');
    return n == null || (!signed && n < 0) || n.abs() > max
        ? 'Isi angka bulat ${signed ? "" : "0–"}$max.' : null;
  }
  Widget input(String key, String label, {String? help,
    String? Function(String?)? validate, bool text = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(controller: field(key),
      keyboardType: text ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true, signed: true),
      maxLength: key == 'name' ? 200 : key == 'group' ? 100 : key == 'note' ? 2000 : null,
      maxLines: key == 'note' ? 3 : 1,
      decoration: InputDecoration(labelText: label, helperText: help, helperMaxLines: 4),
      validator: validate ?? (text ? null : (v) => whole(v))),
  );
  void submit() {
    if (!form.currentState!.validate()) return;
    PlanRule? rule;
    if (kind == 'subscription') {
      rule = PlanRule(kind: kind, currency: currency,
        price: (double.parse(field('price').text) * (currency == 'USD' ? 100 : 1)).round(),
        taxBps: (double.parse(field('tax').text) * 100).round(),
        months: months, taxIncluded: included, enabled: enabled);
    } else if (kind == 'saving') {
      rule = PlanRule(kind: kind, target: int.parse(field('target').text),
        weight: int.parse(field('weight').text), priority: int.parse(field('priority').text),
        enabled: enabled);
    }
    final amount = kind == 'fixed' ? int.parse(field('amount').text) : widget.item?.amount ?? 0;
    final updated = AllocationItem(
      id: widget.item?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: field('name').text.trim(), group: field('group').text.trim(),
      note: field('note').text, amount: amount,
      done: (widget.item?.done ?? false) && amount == widget.item?.amount,
      rule: rule, actual: int.tryParse(field('actual').text),
      opening: int.parse(field('opening').text), spent: int.parse(field('spent').text),
      rollover: rollover,
    );
    Navigator.pop(context, PlanItemEdit(updated));
  }
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.item == null ? 'Tambah pos' : 'Ubah pos',
          style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        input('name', 'Nama pos', text: true,
          validate: (v) => v!.trim().isEmpty ? 'Isi nama pos.' : null),
        input('group', 'Kelompok (potongan: Potongan gaji)', text: true,
          validate: (v) => v!.trim().isEmpty ? 'Isi kelompok.'
            : v.trim() == 'Potongan gaji' && kind != 'fixed'
                ? 'Potongan gaji harus berupa pos tetap.' : null),
        if (widget.allowRules) ...[
          DropdownButtonFormField<String>(isExpanded: true, initialValue: kind,
            decoration: const InputDecoration(labelText: 'Jenis alokasi'),
            items: const [DropdownMenuItem(value: 'fixed', child: Text('Nominal tetap')),
              DropdownMenuItem(value: 'subscription', child: Text('Langganan / tagihan')),
              DropdownMenuItem(value: 'saving', child: Text('Tabungan otomatis'))],
            onChanged: (v) => setState(() => kind = v!)),
          const SizedBox(height: 20),
        ],
        if (kind == 'fixed') input('amount', 'Rencana nominal (rupiah)'),
        if (kind == 'subscription') ...[
          DropdownButtonFormField<String>(isExpanded: true, initialValue: currency,
            decoration: const InputDecoration(labelText: 'Mata uang tagihan'),
            items: const [DropdownMenuItem(value: 'IDR', child: Text('Rupiah (IDR)')),
              DropdownMenuItem(value: 'USD', child: Text('Dolar AS (USD)'))],
            onChanged: (v) => setState(() => currency = v!)),
          const SizedBox(height: 20),
          input('price', 'Harga tagihan ($currency)',
            help: currency == 'USD' ? 'Kurs bulan ini: Rp${widget.fx} per USD.' : null,
            validate: (v) {
              final n = double.tryParse(v ?? '');
              if (n == null || !n.isFinite || n < 0 || n > 1000000000) return 'Isi harga 0–1 miliar.';
              if (currency == 'IDR' && n != n.roundToDouble()) return 'Rupiah harus bulat.';
              if (currency == 'USD' && (n * 100 - (n * 100).round()).abs() > .00001) return 'Maksimal 2 desimal.';
              if (currency == 'USD' && enabled && widget.fx <= 0) return 'Isi kurs di Ubah pendapatan dahulu.';
              return null;
            }),
          input('tax', 'Pajak (%)', validate: (v) {
            final n = double.tryParse(v ?? '');
            return n == null || !n.isFinite || n < 0 || n > 100 ? 'Isi 0–100.' : null;
          }),
          CheckboxListTile(contentPadding: EdgeInsets.zero,
            title: const Text('Harga sudah termasuk pajak'),
            value: included, onChanged: (v) => setState(() => included = v!)),
          DropdownButtonFormField<int>(isExpanded: true, initialValue: months,
            decoration: const InputDecoration(labelText: 'Periode tagihan'),
            items: const [DropdownMenuItem(value: 1, child: Text('Bulanan')),
              DropdownMenuItem(value: 12, child: Text('Tahunan (÷ 12)'))],
            onChanged: (v) => setState(() => months = v!)),
          const SizedBox(height: 16),
        ],
        if (kind == 'saving') ...[
          input('target', 'Target dasar per bulan (rupiah)',
            help: 'Dipenuhi menurut prioritas setelah seluruh pos tetap.'),
          input('priority', 'Prioritas (1 paling dahulu)',
            validate: (v) => whole(v, max: 10000) ?? (v == '0' ? 'Mulai dari prioritas 1.' : null)),
          input('weight', 'Porsi sisa (%)', validate: (v) => whole(v, max: 10000),
            help: 'Sisa dibagi menurut perbandingan porsi semua tabungan otomatis. Isi 0 jika tidak mendapat sisa.'),
        ],
        if (kind != 'fixed') SwitchListTile(contentPadding: EdgeInsets.zero,
          title: const Text('Aktif dalam rencana'), value: enabled,
          onChanged: (v) => setState(() => enabled = v)),
        if (widget.allowRules) CheckboxListTile(contentPadding: EdgeInsets.zero,
          title: const Text('Bawa saldo dana ke bulan berikutnya'),
          subtitle: const Text('Untuk liburan, pajak, servis, atau dana tujuan.'),
          value: rollover, onChanged: (v) => setState(() => rollover = v!)),
        if (widget.allowActual) ExpansionTile(tilePadding: EdgeInsets.zero,
          title: const Text('Realisasi & saldo dana'), children: [
            input('actual', 'Alokasi aktual (rupiah)',
              help: 'Setoran atau pembayaran yang benar-benar sudah dilakukan. Centang saja tidak mengisi nominal.',
              validate: (v) => v!.isEmpty ? null : whole(v)),
            if (rollover) ...[
              input('opening', 'Saldo awal dana (rupiah)', validate: (v) => whole(v, signed: true)),
              input('spent', 'Dana dipakai bulan ini (rupiah)'),
            ],
          ]),
        const SizedBox(height: 16),
        input('note', 'Catatan', text: true),
        FilledButton(onPressed: submit, child: const Text('Terapkan')),
        if (widget.item != null) TextButton(
          onPressed: () => Navigator.pop(context, const PlanItemEdit(null, delete: true)),
          child: const Text('Hapus pos')),
      ])),
  );
}

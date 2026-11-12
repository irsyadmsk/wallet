import 'dart:async';
import 'package:financial_recording/data/services/currency/currency_service.dart';
import 'package:financial_recording/presentation/monthly/plan_item_sheet.dart';
import 'package:financial_recording/util/browser/unsaved_guard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/data/services/monthly_plan_service.dart';
import 'package:financial_recording/data/services/supabase_service.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';

class MonthlyPlanView extends StatelessWidget {
  const MonthlyPlanView({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: SupabaseService.onAuthStateChange,
    builder: (context, _) {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) {
        return const Center(
          child: Text('Masuk untuk membuka rencana pribadi.'),
        );
      }
      return MonthlyPlanEditor(
        key: ValueKey(uid),
        service: MonthlyPlanService(uid),
      );
    },
  );
}

class MonthlyPlanEditor extends StatefulWidget {
  final MonthlyPlanService service;
  const MonthlyPlanEditor({super.key, required this.service});
  @override
  State<MonthlyPlanEditor> createState() => MonthlyPlanEditorState();
}

class MonthlyPlanEditorState extends State<MonthlyPlanEditor> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  String tab = 'month';
  PlanSnapshot? snapshot;
  bool busy = true, unsafe = false;
  String message = '';
  int epoch = 0;
  final _search = TextEditingController();
  String _query = '';
  bool _onlyOpen = false;
  final Set<String> _collapsedGroups = {};
  void Function()? _removeGuard;
  void guardClosing(bool enabled) {
    if (enabled) {
      _removeGuard ??= warnBeforeClosing();
    } else {
      _removeGuard?.call();
      _removeGuard = null;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _removeGuard?.call();
    epoch++;
    super.dispose();
  }

  String get period =>
      tab == 'month' ? DateFormat('yyyy-MM').format(month) : tab;
  final money = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load({bool serverOnly = false}) async {
    final request = ++epoch, key = period;
    setState(() {
      busy = true;
      message = '';
      snapshot = null;
    });
    try {
      final cache = await widget.service.cached(key);
      PlanSnapshot? result;
      String status = '';
      if (cache?.pending == true && !serverOnly) {
        result = cache;
        status = cache!.deviceSaved
            ? 'Tersimpan di perangkat. Simpan ke akun untuk sinkronisasi.'
            : 'Salinan sementara di memori. Penyimpanan perangkat gagal; simpan ke akun sebelum menutup.';
      } else {
        try {
          result = await widget.service.remote(key);
          if (result == null && tab == 'month') {
            final next = await newMonthPlan(key);
            result = PlanSnapshot(
              next,
              0,
              pending: true,
            );
            status =
                'Bulan baru: ceklis, bonus, dan aktual dikosongkan. Saldo dana disalin dari bulan sebelumnya; simpan ke akun.';
          }
          result ??= PlanSnapshot(MonthlyPlan(), 0, pending: true);
          await widget.service.store(key, result);
        } catch (_) {
          if (serverOnly) rethrow;
          if (cache != null) {
            result = cache;
            status = 'Salinan perangkat. Server belum dapat diperiksa.';
          } else if (tab == 'month') {
            final next = await newMonthPlan(key, offline: true);
            result = PlanSnapshot(
              next,
              0,
              pending: true,
            );
            await widget.service.store(key, result);
            status =
                'Draf dari template perangkat. Versi bulan di server belum diperiksa; konflik akan dicegah saat simpan.';
          } else {
            rethrow;
          }
        }
      }
      if (!mounted || request != epoch) return;
      setState(() {
        snapshot = result;
        busy = false;
        unsafe = !(result?.deviceSaved ?? false);
        guardClosing(unsafe);
        message = status.isEmpty ? 'Tersimpan di akun.' : status;
      });
    } catch (_) {
      if (!mounted || request != epoch) return;
      setState(() {
        busy = false;
        message =
            'Rencana gagal dimuat. Periksa koneksi lalu coba lagi. Data lama tidak ditimpa.';
      });
    }
  }

  Future<MonthlyPlan> newMonthPlan(String key, {bool offline = false}) async {
    final date = DateTime.parse('$key-01');
    final previousKey = DateFormat('yyyy-MM').format(DateTime(date.year, date.month - 1));
    final read = offline ? widget.service.cached : widget.service.remote;
    var previous = await read(previousKey);
    final pending = await widget.service.cached(previousKey);
    if (pending?.pending == true) previous = pending;
    final template = await read('template');
    if (offline && template == null && previous == null) {
      throw StateError('Belum ada salinan rencana.');
    }
    return (template?.plan ?? previous?.plan ?? MonthlyPlan())
      .forNewMonth(previous: previous?.plan);
  }

  Future<void> change(MonthlyPlan plan) async {
    final current = snapshot;
    if (busy || current == null) return;
    final request = epoch, key = period;
    try {
      plan = MonthlyPlan.fromJson(MonthlyPlan.fromJson(plan.toJson()).recalculate().toJson());
    } on FormatException catch (e) {
      setState(() => message = e.message);
      return;
    }
    final next = PlanSnapshot(plan, current.revision, pending: true);
    guardClosing(true);
    setState(() {
      snapshot = next;
      busy = true;
      unsafe = true;
      message = 'Menyimpan ke perangkat…';
    });
    try {
      await widget.service.store(key, next);
      if (!mounted || request != epoch) return;
      setState(() {
        unsafe = false;
        guardClosing(false);
        message = 'Tersimpan di perangkat. Belum tersinkron ke akun.';
      });
    } catch (_) {
      if (!mounted || request != epoch) return;
      setState(() {
        message =
            'Penyimpanan perangkat gagal. Perubahan masih di layar; tekan Simpan ke akun sebelum keluar.';
      });
    } finally {
      if (mounted && request == epoch) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    final current = snapshot;
    if (busy || current == null) return;
    final request = epoch, key = period;
    setState(() {
      busy = true;
      message = 'Menyimpan ke akun…';
    });
    try {
      final saved = await widget.service.save(key, current);
      if (!mounted || request != epoch) return;
      setState(() {
        snapshot = saved;
        unsafe = false;
        guardClosing(false);
        message = saved.deviceSaved
            ? 'Tersimpan di akun dan perangkat.'
            : 'Tersimpan di akun. Salinan perangkat belum berhasil diperbarui.';
      });
    } catch (_) {
      if (!mounted || request != epoch) return;
      setState(() {
        message =
            'Simpan belum terkonfirmasi. Periksa koneksi. Jika versi berbeda, tinjau versi server; perubahan di layar tetap ada.';
      });
    } finally {
      if (mounted && request == epoch) setState(() => busy = false);
    }
  }

  Future<void> reviewServer() async {
    if (busy || snapshot == null) return;
    setState(() => busy = true);
    final request = epoch;
    try {
      final remote = await widget.service.remote(period);
      if (!mounted || request != epoch) return;
      if (remote == null) {
        setState(
          () => message = 'Belum ada versi server. Gunakan Simpan ke akun.',
        );
        return;
      }
      final merge = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Versi server'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Versi server ditampilkan di bawah. Gunakan versi layar akan menggantinya dengan rencana di layar; perubahan layar tetap ada sampai penyimpanan berhasil.',
                ),
                Text('Bruto: ${money.format(remote.plan.gross)}'),
                Text('Bonus: ${money.format(remote.plan.bonus)} · kurs: ${remote.plan.fx}'),
                Text('Dana tersedia: ${money.format(remote.plan.available)}'),
                for (final item in remote.plan.items)
                  Text(
                    '${item.done ? "✓" : "—"} ${item.name}: ${money.format(item.amount)}'
                    '${item.actual != null ? " · aktual ${money.format(item.actual)}" : ""}'
                    '${item.rollover ? " · saldo dana ${money.format(item.balance)}" : ""}'
                    '${item.rule?.kind == "saving" ? " · prioritas ${item.rule!.priority}, porsi ${item.rule!.weight}" : ""}'
                    '${item.rule?.kind == "subscription" ? " · ${item.rule!.currency} ${item.rule!.price / (item.rule!.currency == "USD" ? 100 : 1)}, pajak ${item.rule!.taxBps / 100}% (${item.rule!.taxIncluded ? "termasuk" : "ditambah"}), ${item.rule!.months} bulan" : ""}',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Gunakan versi layar dan simpan'),
            ),
          ],
        ),
      );
      if (merge == true && mounted && request == epoch) {
        final combined = PlanSnapshot(
          snapshot!.plan,
          remote.revision,
          pending: true,
        );
        final saved = await widget.service.save(period, combined);
        if (!mounted || request != epoch) return;
        setState(() {
          snapshot = saved;
          unsafe = false;
          message = 'Hasil gabungan tersimpan di akun dan perangkat.';
        });
      }
      // A newer server revision still conflicts, including while this dialog is open.
    } catch (_) {
      if (mounted) setState(() => message = 'Versi server belum dapat dimuat.');
    } finally {
      if (mounted && request == epoch) setState(() => busy = false);
    }
  }

  Future<void> editIncome() async {
    final plan = snapshot!.plan, request = epoch;
    var gross = '${plan.gross}', received = plan.received?.toString() ?? '';
    var bonus = '${plan.bonus}';
    var fxText = '${plan.fx}', fxRevision = 0;
    final form = GlobalKey<FormState>();
    var checking = false, rateNote = '';
    final result = await showAdaptiveSheet<bool>(context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, updateForm) =>
        SingleChildScrollView(padding: const EdgeInsets.all(24),
          child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Pendapatan & kurs', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextFormField(initialValue: gross, onChanged: (v) => gross = v,
                decoration: const InputDecoration(labelText: 'Bruto (rupiah)'),
                keyboardType: TextInputType.number, validator: amountError),
              const SizedBox(height: 16),
              TextFormField(initialValue: received, onChanged: (v) => received = v,
                decoration: const InputDecoration(labelText: 'Benar-benar diterima (opsional)',
                  helperText: 'Gaji bersih sebelum bonus. Kosongkan untuk memakai bruto − Potongan gaji.',
                  helperMaxLines: 3),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? null : amountError(v)),
              const SizedBox(height: 16),
              TextFormField(initialValue: bonus, onChanged: (v) => bonus = v,
                decoration: const InputDecoration(labelText: 'Bonus bersih (rupiah)'),
                keyboardType: TextInputType.number, validator: amountError),
              const SizedBox(height: 16),
              TextFormField(key: ValueKey('fx-$fxRevision'), initialValue: fxText,
                onChanged: (v) => fxText = v,
                decoration: const InputDecoration(labelText: 'Kurs USD/IDR bulan ini',
                  helperText: 'Isi kurs pembayaran, atau gunakan referensi Wallet. Periode lain tetap.', helperMaxLines: 3),
                keyboardType: TextInputType.number, validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0 || n > 1000000) return 'Isi 0–1000000 rupiah per dolar.';
                  if (n == 0 && plan.items.any((i) => i.rule?.kind == 'subscription' &&
                      i.rule!.enabled && i.rule!.currency == 'USD')) return 'Kurs diperlukan untuk langganan dolar.';
                  return null;
                }),
              TextButton.icon(onPressed: checking ? null : () async {
                updateForm(() { checking = true; rateNote = ''; });
                try {
                  final service = CurrencyService.instance;
                  final ok = await service.refresh(force: true);
                  if (!ctx.mounted) return;
                  final rate = service.rate('USD');
                  updateForm(() {
                    if (ok && rate != null && rate.isFinite && rate > 0 && rate <= 1000000) {
                      fxText = '${rate.round()}';
                      fxRevision++;
                      rateNote = 'Referensi ${service.ratesDate ?? "terbaru"}; terapkan untuk bulan ini.';
                    } else { rateNote = 'Kurs belum dapat diperbarui. Isian sebelumnya dipertahankan.'; }
                  });
                } catch (_) {
                  if (ctx.mounted) updateForm(() => rateNote = 'Kurs belum tersedia. Isi manual.');
                } finally {
                  if (ctx.mounted) updateForm(() => checking = false);
                }
              }, icon: const Icon(Icons.currency_exchange),
                label: Text(checking ? 'Memeriksa kurs…' : 'Gunakan kurs Wallet')),
              if (rateNote.isNotEmpty) Text(rateNote, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 20),
              FilledButton(onPressed: checking ? null : () {
                if (form.currentState!.validate()) Navigator.pop(ctx, true);
              }, child: const Text('Terapkan')),
            ]))),
      )),
    );
    final fxValue = int.tryParse(fxText) ?? plan.fx;
    if (result == true && mounted && request == epoch) {
      await change(plan.copy(gross: int.parse(gross), bonus: int.parse(bonus),
        received: int.tryParse(received), clearReceived: received.isEmpty, fx: fxValue));
    }
  }

  String? amountError(String? value) {
    final n = int.tryParse(value ?? '');
    return n == null || n < 0 || n > 1000000000000
        ? 'Isi rupiah bulat 0–1 triliun.'
        : null;
  }

  Future<void> copyToTemplate() async {
    if (busy || snapshot == null) return;
    final request = epoch, plan = snapshot!.plan;
    setState(() => busy = true);
    try {
      final draft = await widget.service.cached('template');
      if (draft?.pending == true) {
        if (mounted && request == epoch) setState(() => message =
          'Template memiliki draf. Buka Template berikutnya dan selesaikan draf dahulu.');
        return;
      }
      final remote = await widget.service.remote('template');
      if (!mounted || request != epoch) return;
      final template = plan.forNewMonth().copy(items: plan.forNewMonth().items
        .map((i) => i.copy(opening: 0)).toList());
      await widget.service.store('template', PlanSnapshot(template,
        remote?.revision ?? 0, pending: true));
      if (!mounted || request != epoch) return;
      setState(() => tab = 'template');
      await load();
      if (mounted) setState(() => message =
        'Draf template dari bulan ini. Tinjau lalu Simpan ke akun untuk bulan baru.');
    } catch (_) {
      if (mounted && request == epoch) setState(() => message =
        'Template belum dapat disalin. Rencana bulan ini tetap tersimpan.');
    } finally {
      if (mounted && request == epoch) setState(() => busy = false);
    }
  }

  Future<void> editItem([AllocationItem? item]) async {
    final plan = snapshot!.plan, request = epoch;
    final result = await showAdaptiveSheet<PlanItemEdit>(context,
      builder: (_) => PlanItemSheet(item: item,
        group: tab == 'reserves' ? 'Persiapan rekening' : 'Rutin',
        fx: plan.fx, allowRules: tab != 'reserves', allowActual: tab == 'month'));
    if (result == null || !mounted || request != epoch) return;
    if (result.delete && item != null) {
      await change(plan.copy(items: plan.items.where((i) => i.id != item.id).toList()));
    } else if (result.item != null) {
      final updated = result.item!;
      await change(plan.copy(items: [for (final i in plan.items)
        if (i.id == updated.id) updated else i,
        if (item == null) updated]));
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = snapshot?.plan, colors = context.colors;
    final visible =
        plan?.items.where((item) {
          final matches = '${item.group} ${item.name} ${item.note}'
              .toLowerCase()
              .contains(_query.trim().toLowerCase());
          return matches && (!_onlyOpen || !item.done);
        }).toList() ??
        <AllocationItem>[];
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Rencana Bulanan'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: ContentShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pendapatan & alokasi',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Atur pendapatan, langganan, dan tabungan di sini. Ceklis tidak mencatat transaksi atau mengubah saldo rekening.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in {
                    'month': 'Bulan',
                    'template': 'Template berikutnya',
                    'reserves': 'Sekali isi rekening',
                  }.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: tab == entry.key,
                      onSelected: busy || unsafe
                          ? null
                          : (_) {
                              setState(() => tab = entry.key);
                              unawaited(load());
                            },
                    ),
                ],
              ),
              if (tab == 'month')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Bulan sebelumnya',
                      onPressed: busy || unsafe
                          ? null
                          : () {
                              setState(
                                () => month = DateTime(
                                  month.year,
                                  month.month - 1,
                                ),
                              );
                              unawaited(load());
                            },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Flexible(
                      child: Text(
                        DateFormat('MMMM yyyy', 'id_ID').format(month),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bulan berikutnya',
                      onPressed: busy || unsafe
                          ? null
                          : () {
                              setState(
                                () => month = DateTime(
                                  month.year,
                                  month.month + 1,
                                ),
                              );
                              unawaited(load());
                            },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              if (tab != 'month')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    tab == 'template'
                        ? 'Perubahan template hanya dipakai saat membuat bulan baru. Riwayat bulan yang sudah ada tetap utuh.'
                        : 'Persiapan dan batas saldo yang diperiksa sekali, berlaku lintas bulan. Centang bukan bukti saldo bank dan bukan pengeluaran.',
                  ),
                ),
              if (busy) const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  style: TextStyle(
                    color: unsafe ? colors.danger : colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (plan == null && !busy)
                OutlinedButton(onPressed: load, child: const Text('Coba lagi')),
              if (plan != null) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: busy ? null : save,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Simpan ke akun'),
                    ),
                    OutlinedButton(
                      onPressed: busy ? null : reviewServer,
                      child: const Text('Tinjau versi server'),
                    ),
                    if (tab == 'month')
                      OutlinedButton.icon(onPressed: busy ? null : copyToTemplate,
                        icon: const Icon(Icons.content_copy_outlined),
                        label: const Text('Salin ke template')),
                    OutlinedButton.icon(
                      onPressed: busy || plan.items.length >= 200
                          ? null
                          : () => editItem(),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah pos'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (tab != 'reserves') ...[
                  Wrap(
                    spacing: 28,
                    runSpacing: 16,
                    children: [
                      _summary('Bruto', money.format(plan.gross)),
                      _summary('Potongan', money.format(plan.deductions)),
                      _summary('Dana tersedia + bonus', money.format(plan.available)),
                      _summary('Langganan / bulan', money.format(plan.digital)),
                      _summary(
                        'Diterima',
                        plan.received == null
                            ? 'Belum diisi'
                            : money.format(plan.received),
                      ),
                    ],
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: busy ? null : editIncome,
                      child: const Text('Ubah pendapatan'),
                    ),
                  ),
                  Text(
                    'Alokasi ${money.format(plan.planned)} · ${plan.unallocated < 0 ? 'Defisit' : 'Belum dialokasikan'} ${money.format(plan.unallocated.abs())}',
                    style: TextStyle(color: plan.unallocated < 0 ? colors.danger : colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text('Aktual tercatat ${money.format(plan.actual)}',
                    style: Theme.of(context).textTheme.bodySmall),
                  if (plan.items.any((i) => i.rule?.kind == 'saving'))
                    const Padding(padding: EdgeInsets.only(top: 8), child: Text(
                      'Tabungan otomatis mengikuti prioritas dan porsi sisa; pos tetap dipertahankan.')),
                  const SizedBox(height: 12),
                ],
                Text(
                  '${plan.items.where((i) => i.done).length}/${plan.items.length} pos ditandai selesai',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: plan.items.isEmpty
                      ? 0
                      : plan.items.where((i) => i.done).length /
                            plan.items.length,
                ),
                if (plan.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Tambah pos tetap, langganan, atau tabungan otomatis. Simpan ke akun agar tersedia di perangkat lain.',
                    ),
                  ),
                if (plan.items.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      labelText: 'Cari pos atau kelompok',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilterChip(
                        label: const Text('Belum selesai'),
                        selected: _onlyOpen,
                        onSelected: (value) =>
                            setState(() => _onlyOpen = value),
                      ),
                      Text(
                        '${visible.length} dari ${plan.items.length} pos',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Tidak ada pos yang cocok. Ubah pencarian atau filter.',
                      ),
                    ),
                  for (final group
                      in visible.map((item) => item.group).toSet()) ...[
                    const SizedBox(height: 20),
                    Semantics(
                      expanded: !_collapsedGroups.contains(group),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          backgroundColor: colors.primaryContainer,
                        ),
                        onPressed: () => setState(() {
                          if (!_collapsedGroups.add(group)) {
                            _collapsedGroups.remove(group);
                          }
                        }),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                group,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${plan.items.where((item) => item.group == group && item.done).length}/${plan.items.where((item) => item.group == group).length}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              _collapsedGroups.contains(group)
                                  ? Icons.expand_more
                                  : Icons.expand_less,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_collapsedGroups.contains(group))
                      for (final item in visible.where(
                        (item) => item.group == group,
                      ))
                        _allocationRow(plan, item),
                  ],
                ],
                const SizedBox(height: 36),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 5),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );

  Widget _allocationRow(MonthlyPlan plan, AllocationItem item) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 600;
            final amount = Text(
              money.format(item.amount),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Checkbox(
                    semanticLabel: 'Selesai: ${item.name}',
                    value: item.done,
                    onChanged: busy || tab == 'template'
                        ? null
                        : (value) => change(
                            plan.copy(
                              items: plan.items
                                  .map(
                                    (other) => other.id == item.id
                                        ? other.copy(done: value)
                                        : other,
                                  )
                                  .toList(),
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      0,
                      12,
                      12,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (!wide)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: amount,
                          ),
                        if (item.rule != null)
                          Padding(padding: const EdgeInsets.only(top: 5), child: Text(
                            item.rule!.kind == 'subscription'
                              ? '${item.rule!.enabled ? "Langganan aktif" : "Dijeda dalam rencana"} · ${item.rule!.months == 12 ? "cadangan tahunan ÷ 12" : "bulanan"} · pajak ${item.rule!.taxIncluded ? "termasuk" : "${item.rule!.taxBps / 100}%"}'
                              : 'Tabungan otomatis · prioritas ${item.rule!.priority} · porsi ${item.rule!.weight}',
                            style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                        if (item.actual != null)
                          Padding(padding: const EdgeInsets.only(top: 5), child: Text(
                            'Aktual ${money.format(item.actual)}',
                            style: TextStyle(color: colors.textSecondary))),
                        if (item.rollover)
                          Padding(padding: const EdgeInsets.only(top: 5), child: Text(
                            'Saldo dana ${money.format(item.balance)} · dibawa ke bulan berikutnya',
                            style: TextStyle(color: item.balance < 0 ? colors.danger : colors.primary))),
                        if (item.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              item.note,
                              style: TextStyle(color: colors.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (wide)
                  SizedBox(
                    width: 150,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        4,
                        12,
                        12,
                        12,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: amount,
                      ),
                    ),
                  ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    tooltip: 'Ubah ${item.name}',
                    onPressed: busy ? null : () => editItem(item),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

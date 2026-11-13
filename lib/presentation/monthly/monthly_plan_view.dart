import 'dart:async';
import 'package:financial_recording/app/demo_mode.dart';
import 'package:financial_recording/data/services/currency/currency_service.dart';
import 'package:financial_recording/presentation/form_tx/view/form_tx_view.dart';
import 'package:financial_recording/presentation/monthly/plan_item_sheet.dart';
import 'package:financial_recording/presentation/monthly/plan_ledger.dart';
import 'package:financial_recording/util/browser/unsaved_guard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/data/services/monthly_plan_service.dart';
import 'package:financial_recording/data/services/supabase_service.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/presentation/monthly/widget/plan_item_tile.dart';
import 'package:financial_recording/presentation/monthly/widget/plan_kind.dart';
import 'package:financial_recording/presentation/monthly/widget/plan_overview.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';

final _demoPlans = DemoPlanService();

class MonthlyPlanView extends StatelessWidget {
  const MonthlyPlanView({super.key});
  @override
  Widget build(BuildContext context) => kDemoMode
      // Design review only: an in-memory illustrative plan, nothing synced.
      ? MonthlyPlanEditor(service: _demoPlans)
      : StreamBuilder(
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

  /// Read-only view of the ledger for linked items. Defaults to the app's
  /// own ledger when it is open.
  final PlanLedger? ledger;

  /// Opens the transaction form for an item. Defaults to the ordinary form;
  /// the planner itself never writes a transaction.
  final Future<void> Function(BuildContext context, AllocationItem item)? onRecord;
  const MonthlyPlanEditor({super.key, required this.service, this.ledger,
    this.onRecord});
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
  PlanKind? _kind;
  late final PlanLedger ledger = widget.ledger ?? HivePlanLedger.ifOpen();

  Future<void> record(AllocationItem item) async {
    final open = widget.onRecord ?? (context, item) => showAdaptiveSheet<bool>(
      context,
      builder: (_) => FormTxView(
        initialMemo: item.name,
        initialAmount: item.actual ?? item.amount,
        initialCategoryId: item.categoryId,
        initialAccountId: item.accountId,
      ),
    );
    await open(context, item);
    // Linked spending may have changed; the plan document has not.
    if (mounted) setState(() {});
  }
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
      ),
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
        fx: plan.fx, allowRules: tab != 'reserves', allowActual: tab == 'month',
        categories: ledger.categories(), accounts: ledger.accounts(),
        goals: ledger.goals()));
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

  void _switchTab(String next) {
    setState(() => tab = next);
    unawaited(load());
  }

  void _shiftMonth(int by) {
    setState(() => month = DateTime(month.year, month.month + by));
    unawaited(load());
  }

  @override
  Widget build(BuildContext context) {
    final plan = snapshot?.plan, colors = context.colors;
    final kind = tab == 'reserves' ? null : _kind;
    final visible =
        plan?.items.where((item) {
          final matches = '${item.group} ${item.name} ${item.note}'
              .toLowerCase()
              .contains(_query.trim().toLowerCase());
          return matches &&
              (!_onlyOpen || !item.done) &&
              (kind == null || planKindOf(item) == kind);
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
              Text(
                'Atur pendapatan, langganan, dan tabungan di sini. Ceklis tidak mencatat transaksi atau mengubah saldo rekening.',
                style: TextStyle(color: colors.textSecondary),
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
                          : (_) => _switchTab(entry.key),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (tab == 'month') _monthSwitcher(colors),
              if (tab != 'month')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    tab == 'template'
                        ? 'Perubahan template hanya dipakai saat membuat bulan baru. Riwayat bulan yang sudah ada tetap utuh.'
                        : 'Persiapan dan batas saldo yang diperiksa sekali, berlaku lintas bulan. Centang bukan bukti saldo bank dan bukan pengeluaran.',
                  ),
                ),
              const SizedBox(height: 12),
              _status(colors),
              const SizedBox(height: 16),
              if (plan == null && !busy)
                OutlinedButton(onPressed: load, child: const Text('Coba lagi')),
              if (plan != null) ...[
                if (tab != 'reserves') ...[
                  PlanOverview(
                    plan: plan,
                    money: money.format,
                    selected: kind,
                    onSelect: (next) => setState(() => _kind = next),
                    onEditIncome: busy ? null : editIncome,
                  ),
                  if (plan.items.any((i) => i.rule?.kind == 'saving'))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Tabungan otomatis mengikuti prioritas dan porsi sisa; pos tetap dipertahankan.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: busy ? null : save,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Simpan ke akun'),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy || plan.items.length >= 200
                          ? null
                          : () => editItem(),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah pos'),
                    ),
                    if (tab == 'month')
                      OutlinedButton.icon(
                        onPressed: busy ? null : copyToTemplate,
                        icon: const Icon(Icons.content_copy_outlined),
                        label: const Text('Salin ke template'),
                      ),
                    OutlinedButton(
                      onPressed: busy ? null : reviewServer,
                      child: const Text('Tinjau versi server'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Daftar pos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${plan.items.where((i) => i.done).length}/${plan.items.length} pos ditandai selesai',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedProgress(
                  value: plan.items.isEmpty
                      ? 0
                      : plan.items.where((i) => i.done).length /
                            plan.items.length,
                  color: colors.primary,
                  track: colors.border,
                  semanticsLabel: 'Pos yang ditandai selesai',
                ),
                if (plan.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Tambah pos tetap, langganan, atau tabungan otomatis. Simpan ke akun agar tersedia di perangkat lain.',
                    ),
                  ),
                if (plan.items.isNotEmpty) ...[
                  const SizedBox(height: 20),
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
                      if (kind != null)
                        InputChip(
                          label: Text('Bagian: ${kind.label}'),
                          deleteButtonTooltipMessage: 'Tampilkan semua bagian',
                          onDeleted: () => setState(() => _kind = null),
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
                    const SizedBox(height: 12),
                    _groupCard(plan, group, visible, colors),
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

  Widget _monthSwitcher(AppColors colors) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: colors.surface,
      border: Border.all(color: colors.border),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Bulan sebelumnya',
          onPressed: busy || unsafe ? null : () => _shiftMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.base),
              switchInCurve: AppMotion.emphasized,
              child: Text(
                DateFormat('MMMM yyyy', 'id_ID').format(month),
                key: ValueKey(month),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Bulan berikutnya',
          onPressed: busy || unsafe ? null : () => _shiftMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );

  Widget _status(AppColors colors) {
    final tone = unsafe ? colors.danger : colors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (busy) const LinearProgressIndicator(),
        if (busy) const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                unsafe ? Icons.error_outline : Icons.cloud_done_outlined,
                size: 16,
                color: tone,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(message, style: TextStyle(color: tone)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _groupCard(
    MonthlyPlan plan,
    String group,
    List<AllocationItem> visible,
    AppColors colors,
  ) {
    final all = plan.items.where((item) => item.group == group).toList();
    final rows = visible.where((item) => item.group == group).toList();
    final collapsed = _collapsedGroups.contains(group);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: !collapsed,
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: const RoundedRectangleBorder(),
                foregroundColor: colors.textPrimary,
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
                    '${all.where((item) => item.done).length}/${all.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: collapsed ? 0 : .5,
                    duration: AppMotion.of(context, AppMotion.base),
                    curve: AppMotion.standard,
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.of(context, AppMotion.base),
            curve: AppMotion.morph,
            alignment: Alignment.topCenter,
            child: collapsed
                ? const SizedBox(width: double.infinity)
                : Column(
                    children: [
                      for (final item in rows) ...[
                        Divider(height: 1, color: colors.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: PlanItemTile(
                            key: ValueKey(item.id),
                            item: item,
                            money: money.format,
                            onToggle: busy || tab == 'template'
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
                            onEdit: busy ? null : () => editItem(item),
                            links: ledger.linksFor(
                              item,
                              tab == 'month' ? month : null,
                            ),
                            onRecord: ledger.available &&
                                    tab == 'month' &&
                                    item.group != 'Potongan gaji'
                                ? () => record(item)
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

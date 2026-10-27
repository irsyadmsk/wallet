import 'dart:async';
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
            final template = await widget.service.remote('template');
            result = PlanSnapshot(
              template?.plan.forNewMonth() ?? MonthlyPlan(),
              0,
              pending: true,
            );
            status =
                'Bulan baru. Status centang dimulai kosong; simpan untuk membuat riwayat bulan ini.';
          }
          result ??= PlanSnapshot(MonthlyPlan(), 0, pending: true);
          await widget.service.store(key, result);
        } catch (_) {
          if (serverOnly) rethrow;
          if (cache != null) {
            result = cache;
            status = 'Salinan perangkat. Server belum dapat diperiksa.';
          } else if (tab == 'month') {
            final template = await widget.service.cached('template');
            if (template == null) rethrow;
            result = PlanSnapshot(
              template.plan.forNewMonth(),
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

  Future<void> change(MonthlyPlan plan) async {
    final current = snapshot;
    if (busy || current == null) return;
    final request = epoch, key = period;
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
                  'Perubahan di layar tetap dipertahankan. Catat perbedaan sebelum menggabungkan secara manual.',
                ),
                Text('Bruto: ${money.format(remote.plan.gross)}'),
                for (final item in remote.plan.items)
                  Text(
                    '${item.done ? "✓" : "—"} ${item.name}: ${money.format(item.amount)}',
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
              child: const Text('Simpan salinan layar sebagai hasil gabungan'),
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
    var gross = '${plan.gross}';
    var received = plan.received?.toString() ?? '';
    final form = GlobalKey<FormState>();
    final result = await showAdaptiveSheet<bool>(
      context,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pendapatan bulan ini',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: gross,
                onChanged: (value) => gross = value,
                decoration: const InputDecoration(labelText: 'Bruto (rupiah)'),
                keyboardType: TextInputType.number,
                validator: amountError,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: received,
                onChanged: (value) => received = value,
                decoration: const InputDecoration(
                  labelText: 'Benar-benar diterima (opsional)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty == true ? null : amountError(v),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (form.currentState!.validate()) Navigator.pop(ctx, true);
                },
                child: const Text('Terapkan'),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == true && mounted && request == epoch) {
      await change(
        plan.copy(
          gross: int.parse(gross),
          received: int.tryParse(received),
          clearReceived: received.isEmpty,
        ),
      );
    }
  }

  String? amountError(String? value) {
    final n = int.tryParse(value ?? '');
    return n == null || n < 0 || n > 1000000000000
        ? 'Isi rupiah bulat 0–1 triliun.'
        : null;
  }

  Future<void> editItem([AllocationItem? item]) async {
    final plan = snapshot!.plan, request = epoch;
    var name = item?.name ?? '';
    var group =
        item?.group ?? (tab == 'reserves' ? 'Persiapan rekening' : 'Rutin');
    var amount = '${item?.amount ?? 0}';
    var note = item?.note ?? '';
    final form = GlobalKey<FormState>();
    final result = await showAdaptiveSheet<bool>(
      context,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item == null ? 'Tambah pos' : 'Ubah pos',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: name,
                onChanged: (value) => name = value,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Nama pos'),
                validator: (v) => v!.trim().isEmpty ? 'Isi nama pos.' : null,
              ),
              TextFormField(
                initialValue: group,
                onChanged: (value) => group = value,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Kelompok (potongan: Potongan gaji)',
                ),
                validator: (v) => v!.trim().isEmpty ? 'Isi kelompok.' : null,
              ),
              TextFormField(
                initialValue: amount,
                onChanged: (value) => amount = value,
                decoration: const InputDecoration(
                  labelText: 'Rencana nominal (rupiah)',
                ),
                keyboardType: TextInputType.number,
                validator: amountError,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: note,
                onChanged: (value) => note = value,
                maxLength: 2000,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Catatan'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (form.currentState!.validate()) Navigator.pop(ctx, true);
                },
                child: const Text('Terapkan'),
              ),
              if (item != null)
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hapus pos'),
                ),
            ],
          ),
        ),
      ),
    );
    if (result == false && item != null && mounted && request == epoch) {
      await change(
        plan.copy(items: plan.items.where((i) => i.id != item.id).toList()),
      );
    }
    if (result == true && mounted && request == epoch) {
      final updated = AllocationItem(
        id: item?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        group: group.trim(),
        name: name.trim(),
        amount: int.parse(amount),
        note: note,
        done: item?.done ?? false,
      );
      await change(
        plan.copy(
          items: [
            for (final i in plan.items)
              if (i.id == updated.id) updated else i,
            if (item == null) updated,
          ],
        ),
      );
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
                'Rencana pribadi',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Checklist alokasi terpisah dari transaksi dan buku keluarga. Centang menandai rencana selesai; saldo dan laporan pengeluaran tidak berubah.',
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
                      _summary('Neto rencana', money.format(plan.net)),
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
                    'Alokasi ${money.format(plan.planned)} · Belum dialokasikan ${money.format(plan.net - plan.planned)}',
                  ),
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
                      'Belum ada pos. Tambahkan rencana Anda, lalu simpan ke akun.',
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

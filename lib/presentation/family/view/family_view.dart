import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/data/services/currency/currency_service.dart';
import 'package:financial_recording/app/app_events.dart';
import 'package:financial_recording/app/sync_controller.dart';
import 'package:financial_recording/data/repositories/tx_query.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/family_service.dart';
import 'package:financial_recording/data/services/supabase_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/presentation/auth/controller/auth_controller.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';
import 'package:financial_recording/util/money/money_format.dart';

/// Family ledger ("akun keluarga"): create one, join by invite code, see
/// members and what each recorded this month, or leave.
class FamilyView extends StatelessWidget {
  const FamilyView({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = Get.find<SyncController>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Keluarga')),
      body: RefreshIndicator(
        onRefresh: () => sync.refreshFamily(reconcile: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ContentShell(
            child: Obx(() {
              dataVersion.value; // rebuild after syncs
              final h = sync.household.value;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: h == null
                    ? const _NoFamily(key: ValueKey('none'))
                    : _FamilyDetail(key: ValueKey(h.id), household: h),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NoFamily extends StatefulWidget {
  const _NoFamily({super.key});

  @override
  State<_NoFamily> createState() => _NoFamilyState();
}

class _NoFamilyState extends State<_NoFamily> {
  final _sync = Get.find<SyncController>();
  final _auth = Get.find<AuthController>();
  final _familyName = TextEditingController();
  final _code = TextEditingController();
  String? _createError;
  String? _joinError;

  @override
  void dispose() {
    _familyName.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _familyName.text.trim();
    if (name.isEmpty) {
      setState(() => _createError = 'Beri nama keluarga, misalnya "Keluarga Irsyad".');
      return;
    }
    final err = await _sync.createFamily(name, _auth.displayName);
    if (mounted) setState(() => _createError = err);
  }

  Future<void> _join() async {
    final code = _code.text.trim().toUpperCase();
    if (code.length != 8) {
      setState(() => _joinError = 'Kode undangan terdiri dari 8 huruf/angka.');
      return;
    }
    var bringData = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Gabung ke buku kas keluarga?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perangkat ini akan menampilkan buku kas keluarga, dan semua catatan anggota langsung terlihat di sini.',
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: bringData,
                onChanged: (v) => setDialog(() => bringData = v ?? true),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Bawa catatan saya ke keluarga'),
                subtitle: const Text(
                  'Akun, transaksi, dan anggaran Anda digabung ke buku kas keluarga. '
                  'Kategori yang sama tidak diduplikasi. Salinan pribadi tetap tersimpan di akun Anda.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gabung')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final err = await _sync.joinFamily(code, _auth.displayName, bringData: bringData);
    if (mounted) setState(() => _joinError = err);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final create = _Panel(
      title: 'Buat keluarga baru',
      body: 'Anda menjadi pemilik. Buku kas Anda saat ini menjadi buku kas keluarga, dan Anda mendapat kode untuk mengundang anggota.',
      children: [
        TextField(
          controller: _familyName,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: 'Nama keluarga', hintText: 'Keluarga Irsyad', errorText: _createError),
          onSubmitted: (_) => _create(),
        ),
        const SizedBox(height: 14),
        Obx(() => WButton(label: 'Buat keluarga', arrow: true, loading: _sync.familyBusy.value, onPressed: _create)),
      ],
    );

    final join = _Panel(
      title: 'Gabung dengan kode',
      body: 'Minta kode undangan 8 karakter dari pemilik keluarga, lalu masukkan di sini.',
      children: [
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
            TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
          ],
          style: AppTypography.numeric(size: 22, weight: FontWeight.w600, color: c.textPrimary).copyWith(letterSpacing: 6),
          decoration: InputDecoration(labelText: 'Kode undangan', counterText: '', errorText: _joinError),
          onSubmitted: (_) => _join(),
        ),
        const SizedBox(height: 14),
        Obx(() => WButton(
              label: 'Gabung',
              variant: WButtonVariant.outline,
              loading: _sync.familyBusy.value,
              onPressed: _join,
            )),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Satu buku kas,\n', style: t.displaySmall),
              TextSpan(text: 'untuk seisi rumah.', style: AppTypography.serif(size: 38, color: c.textSecondary)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Reveal(
          index: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'Anggota keluarga melihat dan mencatat di buku kas yang sama secara langsung. '
              'Setiap transaksi menyimpan nama pencatatnya, dan laporan bisa dirinci per anggota.',
              style: t.bodyLarge?.copyWith(color: c.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 28),
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: Reveal(index: 2, child: create)),
                const SizedBox(width: 16),
                Expanded(child: Reveal(index: 3, child: join)),
              ],
            ),
          )
        else ...[
          Reveal(index: 2, child: create),
          const SizedBox(height: 16),
          Reveal(index: 3, child: join),
        ],
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.body, required this.children});
  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(body, style: TextStyle(color: c.textSecondary, height: 1.45)),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FamilyDetail extends StatelessWidget {
  const _FamilyDetail({super.key, required this.household});
  final Household household;

  @override
  Widget build(BuildContext context) {
    final sync = Get.find<SyncController>();
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final me = SupabaseService.currentUser?.id;
    final isOwner = household.ownerId == me;

    // What each member recorded this month, from the shared ledger.
    final now = DateTime.now();
    final txs = TxRepository().query(TxQuery(from: DateTime(now.year, now.month, 1), to: DateTime(now.year, now.month + 1, 1)));
    final spent = <String, int>{};
    final count = <String, int>{};
    for (final tx in txs) {
      final who = tx.createdBy ?? household.ownerId;
      count[who] = (count[who] ?? 0) + 1;
      if (tx.type == TxType.expense) spent[who] = (spent[who] ?? 0) + tx.idr;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Keluarga', style: AppTypography.serif(size: 26, color: c.textSecondary)),
                    Text(household.name, style: t.displaySmall),
                  ],
                ),
              ),
              if (isOwner)
                WIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Ganti nama keluarga',
                  onPressed: () => _rename(context, sync),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Reveal(index: 1, child: _InviteCard(household: household, isOwner: isOwner)),
        const SizedBox(height: 24),
        Text('Anggota', style: t.titleLarge),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < sync.members.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 72),
                Reveal(
                  index: i + 2,
                  child: _MemberRow(
                    member: sync.members[i],
                    isMe: sync.members[i].userId == me,
                    canRemove: isOwner && sync.members[i].userId != me,
                    spent: spent[sync.members[i].userId] ?? 0,
                    count: count[sync.members[i].userId] ?? 0,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!isOwner)
          Obx(() {
            sync.ownLedgerMergedTick.value;
            if (sync.ownLedgerMerged) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Catatan pribadi Anda', style: t.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Catatan yang Anda buat sebelum bergabung belum ada di buku kas keluarga. '
                        'Gabungkan agar semua terlihat di satu tempat.',
                        style: TextStyle(color: c.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      WButton(
                        label: 'Gabungkan catatan pribadi saya',
                        icon: Icons.merge_rounded,
                        loading: sync.familyBusy.value,
                        onPressed: () async {
                          final err = await sync.mergeOwnLedger();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(err ?? 'Catatan pribadi Anda sudah tergabung ke buku kas keluarga.'),
                            ));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 28),
        WButton(
          label: isOwner ? 'Bubarkan keluarga' : 'Keluar dari keluarga',
          icon: Icons.logout_rounded,
          variant: WButtonVariant.ghost,
          onPressed: () => _leave(context, sync, isOwner),
        ),
      ],
    );
  }

  Future<void> _rename(BuildContext context, SyncController sync) async {
    final ctrl = TextEditingController(text: household.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nama keluarga'),
        content: TextField(controller: ctrl, autofocus: true, onSubmitted: (v) => Navigator.pop(ctx, v)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Simpan')),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) await sync.renameFamily(name: name.trim());
  }

  Future<void> _leave(BuildContext context, SyncController sync, bool isOwner) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isOwner ? 'Bubarkan keluarga?' : 'Keluar dari keluarga?'),
        content: Text(isOwner
            ? 'Semua anggota akan kembali ke buku kas pribadinya masing-masing. Buku kas ini tetap milik Anda.'
            : 'Perangkat ini kembali ke buku kas pribadi Anda. Catatan yang Anda buat di buku kas keluarga tetap berada di sana.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.colors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isOwner ? 'Bubarkan' : 'Keluar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await sync.leaveFamily();
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.household, required this.isOwner});
  final Household household;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sync = Get.find<SyncController>();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: c.textPrimary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kode undangan', style: TextStyle(color: c.surfaceAlt.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 8),
          SelectableText(
            household.inviteCode,
            style: AppTypography.numeric(size: 36, weight: FontWeight.w600, color: c.surfaceAlt).copyWith(letterSpacing: 8),
          ),
          const SizedBox(height: 6),
          Text(
            'Bagikan kode ini hanya kepada anggota keluarga. Siapa pun yang memilikinya dapat melihat buku kas ini.',
            style: TextStyle(color: c.surfaceAlt.withValues(alpha: 0.7), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              WButton(
                label: 'Salin kode',
                icon: Icons.copy_rounded,
                variant: WButtonVariant.inverse,
                size: WButtonSize.small,
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: 'Gabung ke buku kas "${household.name}" di Wallet (wallet.irsyads.com). '
                        'Menu Keluarga → Gabung dengan kode: ${household.inviteCode}',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Undangan disalin.')));
                },
              ),
              if (isOwner)
                Obx(() => WButton(
                      label: 'Ganti kode',
                      icon: Icons.refresh_rounded,
                      variant: WButtonVariant.inverse,
                      size: WButtonSize.small,
                      loading: sync.familyBusy.value,
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Ganti kode undangan?'),
                            content: const Text('Kode lama tidak bisa dipakai lagi. Anggota yang sudah bergabung tidak terpengaruh.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ganti')),
                            ],
                          ),
                        );
                        if (ok == true) await sync.regenerateCode();
                      },
                    )),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.canRemove,
    required this.spent,
    required this.count,
  });

  final HouseholdMember member;
  final bool isMe;
  final bool canRemove;
  final int spent;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: member.isOwner ? c.textPrimary : c.primaryContainer,
            child: Text(
              member.label.characters.first.toUpperCase(),
              style: TextStyle(color: member.isOwner ? c.surfaceAlt : c.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(member.label, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    if (member.isOwner) _Tag('Pemilik', c.textPrimary),
                    if (isMe) ...[const SizedBox(width: 4), _Tag('Anda', c.primary)],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$count transaksi bulan ini · belanja ${spent.rupiah}',
                  style: TextStyle(fontSize: 12.5, color: c.textSecondary),
                ),
                Text(
                  'Bergabung ${DateFormat('d MMM y', 'id_ID').format(member.joinedAt.toLocal())}',
                  style: TextStyle(fontSize: 12, color: c.textTertiary),
                ),
              ],
            ),
          ),
          if (canRemove)
            WIconButton(
              icon: Icons.person_remove_outlined,
              tooltip: 'Keluarkan ${member.label}',
              color: c.danger,
              onPressed: () async {
                final sync = Get.find<SyncController>();
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Keluarkan ${member.label}?'),
                    content: const Text('Anggota ini tidak lagi bisa melihat atau mencatat di buku kas keluarga.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: ctx.colors.danger),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Keluarkan'),
                      ),
                    ],
                  ),
                );
                if (ok == true) await sync.removeMember(member.userId);
              },
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );
}

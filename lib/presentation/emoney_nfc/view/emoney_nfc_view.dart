import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/services/emoney_card_link.dart';
import 'package:financial_recording/data/services/emoney_nfc_service.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/util/money/money_format.dart';

enum _ScanState { waiting, done, error }

String _issuer(String code, String fallback) => switch (code) {
      'emo' => 'Mandiri e-money',
      'brz' => 'BRI Brizzi',
      'tcs' => 'BNI TapCash',
      'flz' => 'BCA Flazz',
      _ => fallback.isEmpty ? 'Kartu e-money' : fallback,
    };

/// Tap an Indonesian e-money card (e-Money Mandiri; Brizzi, TapCash and
/// Flazz where the card allows) to read its balance — the scan starts as
/// soon as the page opens. The card can then be saved as, or reconciled
/// with, a "Kartu Prabayar" account. Android only.
class EmoneyNfcView extends StatefulWidget {
  const EmoneyNfcView({super.key});

  @override
  State<EmoneyNfcView> createState() => _EmoneyNfcViewState();
}

class _EmoneyNfcViewState extends State<EmoneyNfcView> {
  final _service = EmoneyNfcService();
  final _link = EmoneyCardLink();
  _ScanState _state = _ScanState.waiting;
  NfcStatus _nfc = NfcStatus.on;
  EmoneyCardResult? _result;
  EmoneyScan? _previous;
  AccountModel? _account;
  String? _errorText;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  @override
  void dispose() {
    _service.stopSession();
    super.dispose();
  }

  Future<void> _scan() async {
    final nfc = await _service.status();
    if (!mounted) return;
    setState(() {
      _nfc = nfc;
      _errorText = null;
      _state = nfc == NfcStatus.on ? _ScanState.waiting : _ScanState.error;
      if (nfc == NfcStatus.off) _errorText = 'NFC sedang nonaktif. Aktifkan NFC, lalu ketuk "Pindai lagi".';
      if (nfc == NfcStatus.unsupported) _errorText = 'HP ini tidak memiliki NFC, jadi kartu tidak bisa dipindai.';
    });
    if (nfc != NfcStatus.on) return;
    try {
      final result = await _service.scanOnce();
      final previous = _link.previousOf(result.cardNumber);
      await _link.record(EmoneyScan(
        cardCode: result.cardCode,
        cardName: result.cardName,
        cardNumber: result.cardNumber,
        balance: result.balanceAmount ?? 0,
        at: DateTime.now(),
      ));
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() {
        _result = result;
        _previous = previous;
        _account = _link.accountFor(result.cardNumber);
        _state = _ScanState.done;
      });
    } on EmoneyScanException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScanState.error;
        _errorText = e.message;
      });
    }
  }

  Future<void> _saveAccount() async {
    final r = _result;
    if (r == null) return;
    final account = await _link.createAccount(r);
    _changed = true;
    if (!mounted) return;
    setState(() => _account = account);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Akun "${account.name}" dibuat dengan saldo ${account.cachedBalance.rupiah}.')),
    );
  }

  Future<void> _reconcile() async {
    final r = _result, a = _account;
    if (r == null || a == null) return;
    final diff = await _link.reconcile(a, r.balanceAmount ?? 0);
    _changed = true;
    if (!mounted) return;
    setState(() => _account = _link.accountFor(r.cardNumber));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(diff < 0
          ? 'Pemakaian ${(-diff).rupiah} dicatat sebagai pengeluaran.'
          : 'Isi ulang ${diff.rupiah} dicatat sebagai pemasukan.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cek Saldo Kartu'),
          actions: [
            _NfcPill(status: _nfc, onTap: _service.openSettings),
            IconButton(
              tooltip: 'Riwayat cek saldo',
              icon: const Icon(Icons.history_rounded),
              onPressed: () => _showHistory(context),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_state) {
            _ScanState.waiting => const _WaitingForCard(key: ValueKey('wait')),
            _ScanState.error => _ErrorView(
                key: const ValueKey('err'),
                message: _errorText ?? 'Gagal membaca kartu.',
                nfcOff: _nfc == NfcStatus.off,
                onOpenSettings: _service.openSettings,
                onRetry: _scan,
              ),
            _ScanState.done => _ResultView(
                key: ValueKey(_result?.cardNumber),
                result: _result!,
                previous: _previous,
                account: _account,
                onSave: _saveAccount,
                onReconcile: _reconcile,
                onScanAgain: _scan,
              ),
          },
        ),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    final history = _link.history();
    final colors = context.colors;
    final fmt = DateFormat('d MMM y, HH.mm', 'id_ID');
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
          child: history.isEmpty
              ? const Padding(padding: EdgeInsets.all(32), child: Text('Belum ada riwayat cek saldo.'))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = history[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(EmoneyCardLink.issuerColor(s.cardCode)),
                        child: const Icon(Icons.contactless_rounded, color: Colors.white, size: 20),
                      ),
                      title: Text(_issuer(s.cardCode, s.cardName)),
                      subtitle: Text('${EmoneyCardLink.formatNumber(s.cardNumber)}\n${fmt.format(s.at)}'),
                      isThreeLine: true,
                      trailing: Text(
                        s.balance.rupiah,
                        style: AppTypography.numeric(size: 14, weight: FontWeight.w700, color: colors.textPrimary),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _NfcPill extends StatelessWidget {
  const _NfcPill({required this.status, required this.onTap});
  final NfcStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final on = status == NfcStatus.on;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Tooltip(
        message: 'Pengaturan NFC',
        child: InkWell(
          onTap: status == NfcStatus.unsupported ? null : onTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                const Text('NFC', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(width: 8),
                Icon(on ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                    size: 28, color: on ? colors.primary : colors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaitingForCard extends StatelessWidget {
  const _WaitingForCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.smartphone_rounded, size: 120, color: colors.textSecondary),
                  Positioned(
                    left: 44,
                    top: 70,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Container(
                        width: 70,
                        height: 44,
                        decoration: BoxDecoration(color: colors.textPrimary, borderRadius: BorderRadius.circular(6)),
                        child: Icon(Icons.contactless_rounded, size: 18, color: colors.surface),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Tempelkan kartu pada bagian belakang ponsel',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tahan 2–3 detik tanpa digeser. e-Money Mandiri didukung; Brizzi, TapCash, dan Flazz bila kartunya mengizinkan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    super.key,
    required this.message,
    required this.nfcOff,
    required this.onOpenSettings,
    required this.onRetry,
  });
  final String message;
  final bool nfcOff;
  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(nfcOff ? Icons.nfc_rounded : Icons.error_outline_rounded,
                size: 56, color: nfcOff ? colors.warning : colors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.4)),
            const SizedBox(height: AppSpacing.xl),
            if (nfcOff) ...[
              FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Buka Pengaturan NFC'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(onPressed: onRetry, child: const Text('Pindai lagi')),
            ] else
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Pindai lagi')),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    super.key,
    required this.result,
    required this.previous,
    required this.account,
    required this.onSave,
    required this.onReconcile,
    required this.onScanAgain,
  });

  final EmoneyCardResult result;
  final EmoneyScan? previous;
  final AccountModel? account;
  final VoidCallback onSave;
  final VoidCallback onReconcile;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = Theme.of(context).textTheme;
    final balance = result.balanceAmount ?? 0;
    final prev = previous;
    final acc = account;
    final sinceLast = prev == null ? null : balance - prev.balance;
    final gap = acc == null ? null : balance - acc.cachedBalance;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          _issuer(result.cardCode, result.cardName).toUpperCase(),
          style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w600, color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        _CardFace(result: result),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ketuk kartu untuk menyalin nomor kartu',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: colors.textTertiary),
        ),
        if (prev != null && sinceLast != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: ListTile(
              leading: Icon(
                sinceLast < 0 ? Icons.south_east_rounded : Icons.north_east_rounded,
                color: sinceLast < 0 ? colors.expense : colors.income,
              ),
              title: Text(sinceLast == 0
                  ? 'Saldo sama seperti cek terakhir'
                  : '${sinceLast > 0 ? '+' : '-'}${sinceLast.abs().rupiah} sejak cek terakhir'),
              subtitle: Text('Cek terakhir ${DateFormat('d MMM y, HH.mm', 'id_ID').format(prev.at)} · ${prev.balance.rupiah}'),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: acc == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Belum ada di Wallet', style: t.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Simpan kartu ini sebagai akun Kartu Prabayar agar saldonya ikut dihitung di kekayaan bersih.',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: onSave,
                        icon: const Icon(Icons.add_card_rounded),
                        label: const Text('Simpan sebagai akun'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Terhubung ke akun "${acc.name}"', style: t.titleMedium),
                      const SizedBox(height: 4),
                      Text('Saldo di catatan Wallet: ${acc.cachedBalance.rupiah}', style: TextStyle(color: colors.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      if (gap == 0)
                        Row(children: [
                          Icon(Icons.check_circle_rounded, color: colors.income, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Saldo kartu sama dengan catatan.')),
                        ])
                      else
                        FilledButton.icon(
                          onPressed: onReconcile,
                          icon: const Icon(Icons.sync_alt_rounded),
                          label: Text(gap! < 0 ? 'Catat pemakaian ${(-gap).rupiah}' : 'Catat isi ulang ${gap.rupiah}'),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: onScanAgain,
          icon: const Icon(Icons.contactless_rounded),
          label: const Text('Pindai kartu lain'),
        ),
      ],
    );
  }
}

/// The card itself, in the issuer's colour, like the physical card.
class _CardFace extends StatelessWidget {
  const _CardFace({required this.result});
  final EmoneyCardResult result;

  @override
  Widget build(BuildContext context) {
    final base = Color(EmoneyCardLink.issuerColor(result.cardCode));
    final number = EmoneyCardLink.formatNumber(result.cardNumber);
    final balance = result.balanceAmount;
    return AspectRatio(
      aspectRatio: 1.586, // ID-1 card
      child: Material(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: number.isEmpty
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: EmoneyCardLink.normalize(result.cardNumber)));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor kartu disalin.')));
                },
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(base, Colors.white, 0.28)!, base],
              ),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Saldo', style: TextStyle(color: Colors.white70, fontSize: 15)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              balance == null ? 'Tidak terbaca' : balance.rupiah,
                              style: AppTypography.numeric(size: 34, weight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _issuer(result.cardCode, result.cardName),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
                const Spacer(),
                const Text('Nomor Kartu', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    number.isEmpty ? '—' : number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/services/emoney_nfc_service.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';
import 'package:financial_recording/presentation/accounts/widget/account_editor_sheet.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/art_icon.dart';

enum _ScanState { idle, scanning, done, error }

/// Scan an Indonesian NFC e-money card (Flazz, Brizzi, TapCash, e-Money
/// Mandiri, etc.) and offer to create a "Kartu Prabayar" account from it.
///
/// Experimental and Android-only — see [EmoneyNfcService] for why balance
/// accuracy isn't guaranteed and why a scan never silently overwrites an
/// existing account's balance.
class EmoneyNfcView extends StatefulWidget {
  const EmoneyNfcView({super.key});

  @override
  State<EmoneyNfcView> createState() => _EmoneyNfcViewState();
}

class _EmoneyNfcViewState extends State<EmoneyNfcView> {
  final _service = EmoneyNfcService();
  _ScanState _state = _ScanState.idle;
  EmoneyCardResult? _result;
  String? _errorText;

  @override
  void dispose() {
    _service.stopSession();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _state = _ScanState.scanning;
      _errorText = null;
    });
    try {
      final result = await _service.scanOnce();
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _state = _ScanState.error;
          _errorText = 'NFC tidak tersedia di perangkat ini.';
        });
        return;
      }
      setState(() {
        _result = result;
        _state = _ScanState.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScanState.error;
        _errorText = 'Gagal membaca kartu: $e';
      });
    }
  }

  Future<void> _createAccount() async {
    final r = _result;
    if (r == null) return;
    final balance = r.balanceAmount ?? 0;
    final account = AccountModel(
      id: const Uuid().v4(),
      name: r.cardName.isNotEmpty ? r.cardName : 'Kartu E-Money',
      groupCode: AccountGroupType.prepaid.code,
      openingBalance: balance,
      cachedBalance: balance,
      note: 'Dibuat dari pindai NFC · No. kartu ${r.cardNumber}',
    );
    await AccountRepository().upsert(account);
    if (!mounted) return;
    await showAdaptiveSheet<AccountEditorResult>(
      context,
      builder: (_) => AccountEditorSheet(existing: account),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai Kartu E-Money')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: colors.warning, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Eksperimental, khusus Android. Keandalan baca saldo berbeda-beda '
                      'tergantung penerbit kartu (Flazz, Brizzi, TapCash, e-Money Mandiri, dll) — '
                      'sebagian kartu melindungi saldo dengan kunci milik bank sehingga tidak selalu '
                      'terbaca. Selalu periksa hasilnya sebelum disimpan.',
                      style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (_state == _ScanState.idle) ...[
              ArtIcon(
                size: 96,
                icon: Icons.nfc_rounded,
                iconColor: colors.primary,
                backgroundColor: colors.primaryContainer.withValues(alpha: 0.4),
                showAura: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'Tempelkan kartu e-money ke bagian belakang HP',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.nfc_rounded),
                label: const Text('Mulai Pindai'),
              ),
            ],
            if (_state == _ScanState.scanning) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text('Menunggu kartu di-tap…', style: TextStyle(color: colors.textSecondary)),
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: () {
                  _service.stopSession();
                  setState(() => _state = _ScanState.idle);
                },
                child: const Text('Batal'),
              ),
            ],
            if (_state == _ScanState.error) ...[
              Icon(Icons.error_outline_rounded, color: colors.danger, size: 48),
              const SizedBox(height: AppSpacing.md),
              Center(child: Text(_errorText ?? 'Terjadi kesalahan.', textAlign: TextAlign.center)),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: _startScan, child: const Text('Coba Lagi')),
            ],
            if (_state == _ScanState.done && _result != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ResultRow(label: 'Nama Kartu', value: _result!.cardName),
                      _ResultRow(label: 'Nomor Kartu', value: _result!.cardNumber),
                      _ResultRow(label: 'Saldo Terbaca', value: _result!.balance),
                      _ResultRow(label: 'Kode Kartu', value: _result!.cardCode),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _createAccount,
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Buat Akun Kartu Prabayar dari Data Ini'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: _startScan,
                child: const Text('Pindai Kartu Lain'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:financial_recording/data/services/pin_lock_service.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';

/// Bottom sheet to set (or change) the 4–6 digit app-open PIN. Pops `true`
/// once a PIN is saved.
class PinSetupSheet extends StatefulWidget {
  const PinSetupSheet({super.key});

  @override
  State<PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<PinSetupSheet> {
  final _service = PinLockService();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pin = _pinController.text;
    final confirm = _confirmController.text;
    if (pin.length < 4) {
      setState(() => _error = 'PIN minimal 4 digit.');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'Konfirmasi PIN tidak cocok.');
      return;
    }
    await _service.setPin(pin);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Atur PIN Kunci Aplikasi', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'PIN ini hanya tersimpan di perangkat ini, tidak ikut tersinkron.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              decoration: const InputDecoration(labelText: 'PIN baru (4-6 digit)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _confirmController,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              decoration: const InputDecoration(labelText: 'Ulangi PIN'),
              onSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: _save, child: const Text('Simpan PIN')),
          ],
        ),
      ),
    );
  }
}

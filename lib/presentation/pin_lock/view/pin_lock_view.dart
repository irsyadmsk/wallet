import 'package:flutter/material.dart';
import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/data/services/pin_lock_service.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/art_icon.dart';

const _pinLength = 4;

/// Full-screen PIN gate shown once per app launch when the lock is enabled.
/// Purely a local UI gate — it doesn't touch Supabase auth or sync at all.
class PinLockView extends StatefulWidget {
  const PinLockView({super.key, required this.onUnlocked});
  final VoidCallback onUnlocked;

  @override
  State<PinLockView> createState() => _PinLockViewState();
}

class _PinLockViewState extends State<PinLockView> {
  final _service = PinLockService();
  String _entered = '';
  String? _error;

  void _tap(String d) {
    if (_entered.length >= _pinLength) return;
    setState(() {
      _entered += d;
      _error = null;
    });
    if (_entered.length == _pinLength) _check();
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _check() {
    if (_service.verify(_entered)) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = 'PIN salah, coba lagi.';
        _entered = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ArtIcon(
                size: 72,
                icon: Icons.lock_rounded,
                iconColor: colors.primary,
                backgroundColor: colors.primaryContainer.withValues(alpha: 0.4),
                showAura: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(AppConfig.appName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Masukkan PIN untuk membuka', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pinLength; i++)
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _entered.length ? colors.primary : Colors.transparent,
                        border: Border.all(color: colors.primary, width: 1.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 20,
                child: _error == null
                    ? null
                    : Text(_error!, style: TextStyle(color: colors.danger, fontSize: 12)),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Keypad(onDigit: _tap, onBackspace: _backspace),
            ],
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final k in row)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: k.isEmpty
                        ? null
                        : Material(
                            color: context.colors.surfaceAlt,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => k == '⌫' ? onBackspace() : onDigit(k),
                              child: Center(
                                child: k == '⌫'
                                    ? const Icon(Icons.backspace_outlined)
                                    : Text(k, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

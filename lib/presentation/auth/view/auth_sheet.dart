import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/presentation/auth/controller/auth_controller.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/form/textfield/text_field.dart';

/// Email/password sign-in & sign-up. Reached from Settings > Akun —
/// never a hard gate, the app works fully offline without it.
class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key});

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final _auth = Get.find<AuthController>();
  bool _isSignUp = false;
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              _isSignUp ? 'Buat Akun' : 'Masuk ke Akun',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Sinkronkan data keuangan Anda antar perangkat dengan aman.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),
            QTextField(
              label: 'Email',
              onChanged: (v) => _email = v,
              onSubmitted: (_) => _submit(),
            ),
            QTextField(
              label: 'Kata Sandi',
              obscure: true,
              onChanged: (v) => _password = v,
              onSubmitted: (_) => _submit(),
              helper: _isSignUp ? 'Minimal 6 karakter' : null,
            ),
            Obx(() => _auth.errorText.value == null
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      _auth.errorText.value!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  )),
            Obx(() => FilledButton(
                  onPressed: _auth.busy.value ? null : _submit,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _auth.busy.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isSignUp ? 'Daftar' : 'Masuk'),
                )),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => setState(() {
                _isSignUp = !_isSignUp;
                _auth.errorText.value = null;
              }),
              child: Text(_isSignUp ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_email.trim().isEmpty || _password.isEmpty) {
      _auth.errorText.value = 'Isi email dan kata sandi.';
      return;
    }
    final ok = _isSignUp ? await _auth.signUp(_email, _password) : await _auth.signIn(_email, _password);
    if (ok && _auth.isSignedIn && mounted) {
      Navigator.of(context).pop();
    }
  }
}

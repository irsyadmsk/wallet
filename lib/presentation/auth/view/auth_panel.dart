import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/presentation/auth/controller/auth_controller.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';

enum AuthMode { signIn, signUp, reset }

/// Opens the sign-in / sign-up panel: a right-hand sheet on wide screens,
/// a bottom sheet on phones. Pops itself once a session exists.
Future<void> showAuthPanel(BuildContext context, {AuthMode mode = AuthMode.signIn}) {
  bool isWide(BuildContext c) => MediaQuery.sizeOf(c).width >= 720;
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: AppMotion.of(context, const Duration(milliseconds: 520)),
    // Layout is decided on every build, so rotating a tablet or resizing a
    // browser window swaps between side panel and bottom sheet live.
    pageBuilder: (ctx, _, _) {
      final wide = isWide(ctx);
      final panel = Material(
        color: ctx.colors.surface,
        borderRadius: wide
            ? const BorderRadius.horizontal(left: Radius.circular(28))
            : const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          left: false,
          top: wide,
          child: AuthForm(initialMode: mode, onDone: () => Navigator.of(ctx).maybePop()),
        ),
      );
      return wide
          ? Align(alignment: Alignment.centerRight, child: SizedBox(width: 460, height: double.infinity, child: panel))
          : KeyboardInset(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.94),
                  child: panel,
                ),
              ),
            );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: AppMotion.emphasized, reverseCurve: Curves.easeInCubic);
      return SlideTransition(
        position: Tween(begin: isWide(ctx) ? const Offset(1, 0) : const Offset(0, 1), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

class AuthForm extends StatefulWidget {
  const AuthForm({super.key, this.initialMode = AuthMode.signIn, this.onDone});
  final AuthMode initialMode;
  final VoidCallback? onDone;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _auth = Get.find<AuthController>();
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late AuthMode _mode = widget.initialMode;
  bool _obscure = true;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _auth.errorText.value = null;
    _auth.infoText.value = null;
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _setMode(AuthMode m) {
    setState(() {
      _mode = m;
      _submitted = false;
    });
    _auth.errorText.value = null;
    _auth.infoText.value = null;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!(_form.currentState?.validate() ?? false)) return;
    TextInput.finishAutofillContext();
    final ok = switch (_mode) {
      AuthMode.signIn => await _auth.signIn(_email.text, _password.text),
      AuthMode.signUp => await _auth.signUp(_email.text, _password.text, name: _name.text),
      AuthMode.reset => await _auth.sendPasswordReset(_email.text),
    };
    if (ok && _auth.isSignedIn && mounted) widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = switch (_mode) {
      AuthMode.signIn => 'Selamat datang kembali',
      AuthMode.signUp => 'Buat akun Wallet',
      AuthMode.reset => 'Atur ulang kata sandi',
    };
    final subtitle = switch (_mode) {
      AuthMode.signIn => 'Masuk untuk membuka buku kas Anda di perangkat ini.',
      AuthMode.signUp => 'Satu akun untuk semua perangkat, dan bisa diajak bergabung ke buku kas keluarga.',
      AuthMode.reset => 'Kami kirim tautan ke email Anda untuk membuat kata sandi baru.',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: AutofillGroup(
        child: Form(
          key: _form,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Wallet', style: AppTypography.display(size: 24, weight: FontWeight.w600, color: c.textPrimary)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('*', style: AppTypography.display(size: 14, weight: FontWeight.w600, color: c.textPrimary)),
                  ),
                  const Spacer(),
                  WIconButton(icon: Icons.close_rounded, tooltip: 'Tutup', onPressed: widget.onDone),
                ],
              ),
              const SizedBox(height: 28),
              if (_mode != AuthMode.reset)
                Align(
                  alignment: Alignment.centerLeft,
                  child: PillTabs<AuthMode>(
                    tabs: const [PillTab(AuthMode.signIn, 'Masuk'), PillTab(AuthMode.signUp, 'Daftar')],
                    value: _mode,
                    onChanged: _setMode,
                  ),
                ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.base),
                switchInCurve: AppMotion.emphasized,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topLeft,
                  children: [...previous, if (current != null) current],
                ),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(a), child: child),
                ),
                child: Column(
                  key: ValueKey(_mode),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(subtitle, style: TextStyle(color: c.textSecondary, fontSize: 14.5, height: 1.45)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Obx(() {
                final info = _auth.infoText.value;
                if (info == null) return const SizedBox.shrink();
                return _Notice(text: info, positive: true)
                    .animate()
                    .fadeIn(duration: AppMotion.base)
                    .moveY(begin: 8, end: 0, curve: AppMotion.emphasized);
              }),
              if (_mode == AuthMode.signUp) ...[
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nama panggilan', hintText: 'Contoh: Irsyad'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Isi nama yang akan dilihat anggota keluarga.' : null,
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: _mode == AuthMode.reset ? TextInputAction.done : TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email', hintText: 'nama@email.com'),
                onFieldSubmitted: _mode == AuthMode.reset ? (_) => _submit() : null,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return 'Isi alamat email.';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'Format email belum benar, contoh: nama@email.com';
                  return null;
                },
              ),
              if (_mode != AuthMode.reset) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: _mode == AuthMode.signUp ? TextInputAction.next : TextInputAction.done,
                  autofillHints: [_mode == AuthMode.signUp ? AutofillHints.newPassword : AutofillHints.password],
                  onFieldSubmitted: _mode == AuthMode.signIn ? (_) => _submit() : null,
                  decoration: InputDecoration(
                    labelText: 'Kata sandi',
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Isi kata sandi.';
                    if (_mode == AuthMode.signUp && v.length < 8) return 'Minimal 8 karakter.';
                    return null;
                  },
                ),
                if (_mode == AuthMode.signUp) ...[
                  const SizedBox(height: 10),
                  _StrengthMeter(password: _password.text),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(labelText: 'Ulangi kata sandi'),
                    validator: (v) => v != _password.text ? 'Kata sandi tidak sama.' : null,
                  ),
                ],
              ],
              if (_mode == AuthMode.signIn)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => _setMode(AuthMode.reset), child: const Text('Lupa kata sandi?')),
                )
              else
                const SizedBox(height: 20),
              Obx(() {
                final err = _auth.errorText.value;
                if (err == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _Notice(text: err, positive: false),
                ).animate().fadeIn(duration: AppMotion.base).shakeX(hz: 4, amount: 3, duration: 360.ms);
              }),
              Obx(() => WButton(
                    label: switch (_mode) {
                      AuthMode.signIn => 'Masuk',
                      AuthMode.signUp => 'Buat akun',
                      AuthMode.reset => 'Kirim tautan',
                    },
                    size: WButtonSize.large,
                    arrow: true,
                    expand: true,
                    loading: _auth.busy.value,
                    onPressed: _submit,
                  )),
              const SizedBox(height: 12),
              if (_mode == AuthMode.reset)
                TextButton(onPressed: () => _setMode(AuthMode.signIn), child: const Text('Kembali ke halaman masuk')),
              if (_mode == AuthMode.signUp)
                Obx(() => _auth.infoText.value == null
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: _auth.busy.value ? null : () => _auth.resendConfirmation(_email.text),
                        child: const Text('Belum menerima email? Kirim ulang'),
                      )),
              const SizedBox(height: 16),
              Text(
                'Data Anda disimpan di perangkat dan dicadangkan terenkripsi (TLS) ke server. '
                'Hanya Anda dan anggota keluarga yang Anda undang yang dapat membacanya.',
                style: TextStyle(color: c.textTertiary, fontSize: 12, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.positive});
  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = positive ? c.success : c.danger;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(positive ? Icons.mark_email_read_outlined : Icons.error_outline_rounded, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: c.textPrimary, fontSize: 13.5, height: 1.4))),
          ],
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});
  final String password;

  static int score(String p) {
    var s = 0;
    if (p.length >= 8) s++;
    if (p.length >= 12) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = password.isEmpty ? 0 : score(password);
    final labels = ['Terlalu pendek', 'Lemah', 'Cukup', 'Kuat', 'Sangat kuat'];
    final colors = [c.border, c.danger, c.warning, c.success, c.success];
    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.base,
              curve: AppMotion.standard,
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < s ? colors[s] : c.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        const SizedBox(width: 10),
        SizedBox(
          width: 86,
          child: Text(
            password.isEmpty ? '' : labels[s],
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Shown by the gate after a password-reset link signs the user in.
class SetNewPasswordView extends StatefulWidget {
  const SetNewPasswordView({super.key});

  @override
  State<SetNewPasswordView> createState() => _SetNewPasswordViewState();
}

class _SetNewPasswordViewState extends State<SetNewPasswordView> {
  final _auth = Get.find<AuthController>();
  final _form = GlobalKey<FormState>();
  final _pw = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Buat kata sandi baru', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Gunakan minimal 8 karakter.', style: TextStyle(color: context.colors.textSecondary)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _pw,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(labelText: 'Kata sandi baru'),
                    validator: (v) => (v == null || v.length < 8) ? 'Minimal 8 karakter.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Ulangi kata sandi baru'),
                    validator: (v) => v != _pw.text ? 'Kata sandi tidak sama.' : null,
                  ),
                  const SizedBox(height: 16),
                  Obx(() => _auth.errorText.value == null
                      ? const SizedBox.shrink()
                      : Padding(padding: const EdgeInsets.only(bottom: 12), child: _Notice(text: _auth.errorText.value!, positive: false))),
                  Obx(() => WButton(
                        label: 'Simpan kata sandi',
                        expand: true,
                        size: WButtonSize.large,
                        loading: _auth.busy.value,
                        onPressed: () {
                          if (_form.currentState?.validate() ?? false) _auth.updatePassword(_pw.text);
                        },
                      )),
                  TextButton(
                    onPressed: () => _auth.recoveringPassword.value = false,
                    child: const Text('Lewati untuk sekarang'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:financial_recording/app/demo_mode.dart';
import 'package:financial_recording/app/sync_controller.dart';
import 'package:financial_recording/data/services/current_actor.dart';
import 'package:financial_recording/data/services/supabase_service.dart';
import 'package:financial_recording/data/services/sync/sync_service.dart';

/// Supabase email/password auth. Signing in is required to use the app —
/// the gate in `money_manager_app.dart` shows the welcome screen until
/// [user] is set — and every signed-in session syncs through
/// [SyncController].
class AuthController extends GetxController {
  final user = Rxn<User>();
  final busy = false.obs;
  final errorText = RxnString();
  final infoText = RxnString();

  /// True after the user opens a password-reset link; the gate then asks
  /// for a new password before anything else.
  final recoveringPassword = false.obs;

  StreamSubscription<AuthState>? _authSub;

  SyncController get _sync => Get.find<SyncController>();

  bool get isSignedIn => user.value != null;

  /// Name shown to family members and stamped on new transactions.
  String get displayName {
    final u = user.value;
    if (u == null) return kDemoMode ? 'Irsyad' : '';
    final meta = u.userMetadata?['display_name'];
    if (meta is String && meta.trim().isNotEmpty) return meta.trim();
    final email = u.email ?? '';
    return email.contains('@') ? email.split('@').first : 'Saya';
  }

  // Kept for older call sites that read sync state from here.
  RxBool get syncing => _sync.syncing;
  Rxn<DateTime> get lastSyncAt => _sync.lastSyncAt;
  Future<SyncResult> syncNow() => _sync.syncNow();

  static String? get _redirect => kIsWeb ? Uri.base.origin : 'https://wallet.irsyads.com';

  @override
  void onInit() {
    super.onInit();
    _setUser(SupabaseService.currentUser);
    _authSub = SupabaseService.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        recoveringPassword.value = true;
      }
      final was = user.value?.id;
      _setUser(state.session?.user);
      if (user.value != null && user.value!.id != was) {
        _sync.onSignedIn(user.value!);
      }
    });
    if (isSignedIn) _sync.onSignedIn(user.value!);
  }

  void _setUser(User? u) {
    user.value = u;
    if (u == null) {
      CurrentActor.clear();
    } else {
      CurrentActor.set(id: u.id, name: displayName);
    }
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  Future<bool> signIn(String email, String password) => _run(() async {
        await SupabaseService.auth.signInWithPassword(email: email.trim(), password: password);
      });

  /// Returns true on success. When the project requires email
  /// confirmation there's no session yet — [infoText] explains the next step.
  Future<bool> signUp(String email, String password, {String? name}) => _run(() async {
        final res = await SupabaseService.auth.signUp(
          email: email.trim(),
          password: password,
          emailRedirectTo: _redirect,
          data: {if (name != null && name.trim().isNotEmpty) 'display_name': name.trim()},
        );
        if (res.session == null && res.user != null) {
          infoText.value = 'Akun dibuat. Buka tautan verifikasi yang kami kirim ke ${email.trim()}, lalu masuk.';
        }
      });

  Future<bool> sendPasswordReset(String email) => _run(() async {
        await SupabaseService.auth.resetPasswordForEmail(email.trim(), redirectTo: _redirect);
        infoText.value = 'Tautan atur ulang kata sandi telah dikirim ke ${email.trim()}.';
      });

  Future<bool> resendConfirmation(String email) => _run(() async {
        await SupabaseService.auth.resend(type: OtpType.signup, email: email.trim(), emailRedirectTo: _redirect);
        infoText.value = 'Email verifikasi dikirim ulang ke ${email.trim()}.';
      });

  Future<bool> updatePassword(String newPassword) => _run(() async {
        await SupabaseService.auth.updateUser(UserAttributes(password: newPassword));
        recoveringPassword.value = false;
        infoText.value = 'Kata sandi berhasil diperbarui.';
      });

  Future<bool> updateDisplayName(String name) => _run(() async {
        final res = await SupabaseService.auth.updateUser(UserAttributes(data: {'display_name': name.trim()}));
        _setUser(res.user);
        if (_sync.inFamily) await _sync.renameFamily(displayName: name.trim());
      });

  /// Syncs, wipes this device's copy, then signs out. When the final sync
  /// fails and [force] is false, returns the error and stays signed in so
  /// the UI can warn about unsynced edits.
  Future<String?> signOut({bool force = false}) async {
    busy.value = true;
    try {
      final err = await _sync.flushAndWipe(force: force);
      if (err != null) return err;
      await _sync.onSignedOut();
      await SupabaseService.auth.signOut();
      _setUser(null);
      // Screen controllers cache the previous account's figures; drop them
      // so the next person to sign in on this device never sees them.
      // Permanent services (auth, sync, theme, shell) survive.
      await Get.deleteAll();
      return null;
    } finally {
      busy.value = false;
    }
  }

  Future<bool> _run(Future<void> Function() op) async {
    errorText.value = null;
    infoText.value = null;
    busy.value = true;
    try {
      await op();
      return true;
    } on AuthException catch (e) {
      errorText.value = _translate(e.message);
      return false;
    } catch (e) {
      final s = e.toString();
      errorText.value = s.contains('SocketException') || s.contains('ClientException')
          ? 'Tidak ada koneksi internet. Periksa jaringan Anda lalu coba lagi.'
          : 'Terjadi kesalahan: $s';
      return false;
    } finally {
      busy.value = false;
    }
  }

  /// Supabase returns English messages; show the common ones in Indonesian.
  static String _translate(String m) {
    final l = m.toLowerCase();
    if (l.contains('invalid login credentials')) return 'Email atau kata sandi salah.';
    if (l.contains('email not confirmed')) return 'Email belum diverifikasi. Buka tautan di email Anda terlebih dahulu.';
    if (l.contains('user already registered')) return 'Email ini sudah terdaftar. Silakan masuk.';
    if (l.contains('password should be at least')) return 'Kata sandi minimal 6 karakter.';
    if (l.contains('rate limit') || l.contains('too many')) return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
    if (l.contains('unable to validate email') || l.contains('invalid email')) return 'Format email tidak valid.';
    if (l.contains('same password') || l.contains('different from the old')) return 'Kata sandi baru harus berbeda dari yang lama.';
    if (l.contains('weak') || l.contains('pwned') || l.contains('leaked')) {
      return 'Kata sandi terlalu lemah atau pernah bocor. Gunakan kombinasi yang lebih kuat.';
    }
    return m;
  }
}

import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:financial_recording/data/services/supabase_service.dart';
import 'package:financial_recording/data/services/sync/sync_service.dart';

/// Wraps Supabase auth + [SyncService] for the whole app. The app works
/// fully offline without an account — this only adds optional cross-device
/// sync on top, so login is never a hard gate (see Settings > Akun).
class AuthController extends GetxController {
  final user = Rxn<User>();
  final busy = false.obs;
  final syncing = false.obs;
  final errorText = RxnString();
  final lastSyncAt = Rxn<DateTime>();

  StreamSubscription<AuthState>? _authSub;

  bool get isSignedIn => user.value != null;

  @override
  void onInit() {
    super.onInit();
    user.value = SupabaseService.currentUser;
    lastSyncAt.value = SyncService().lastSyncAt;
    _authSub = SupabaseService.onAuthStateChange.listen((state) {
      user.value = state.session?.user;
      if (user.value != null) {
        // Fire-and-forget: pull/push happens quietly in the background so
        // sign-in doesn't block the UI.
        syncNow();
      }
    });
    if (isSignedIn) syncNow();
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  Future<bool> signIn(String email, String password) async {
    errorText.value = null;
    busy.value = true;
    try {
      await SupabaseService.auth.signInWithPassword(email: email.trim(), password: password);
      return true;
    } on AuthException catch (e) {
      errorText.value = e.message;
      return false;
    } catch (e) {
      errorText.value = 'Gagal masuk: $e';
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    errorText.value = null;
    busy.value = true;
    try {
      final res = await SupabaseService.auth.signUp(email: email.trim(), password: password);
      if (res.session == null && res.user != null) {
        errorText.value = 'Akun dibuat. Cek email untuk verifikasi sebelum masuk.';
      }
      return true;
    } on AuthException catch (e) {
      errorText.value = e.message;
      return false;
    } catch (e) {
      errorText.value = 'Gagal mendaftar: $e';
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<void> signOut() async {
    await SupabaseService.auth.signOut();
    user.value = null;
  }

  Future<SyncResult> syncNow() async {
    if (!isSignedIn || syncing.value) {
      return const SyncResult(pushed: 0, pulled: 0, error: 'Belum login.');
    }
    syncing.value = true;
    try {
      final result = await SyncService().syncNow();
      lastSyncAt.value = SyncService().lastSyncAt;
      if (!result.ok) errorText.value = result.error;
      return result;
    } finally {
      syncing.value = false;
    }
  }
}

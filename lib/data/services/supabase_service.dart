import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project for wallet.irsyads.com — auth + cross-device sync.
///
/// The anon/publishable key below is safe to ship in client code: it only
/// grants what Row Level Security on each table allows (see the
/// `create_sync_tables` migration), never raw table access.
abstract class SupabaseService {
  static const String url = 'https://bqeqcfglpijegxnpncvg.supabase.co';
  static const String publishableKey = 'sb_publishable_cbE4hb1gPJl1kCEWOFxW4A_k0ZORDIS';

  static Future<void> init() async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static User? get currentUser => auth.currentUser;

  static bool get isSignedIn => currentUser != null;

  static Stream<AuthState> get onAuthStateChange => auth.onAuthStateChange;
}

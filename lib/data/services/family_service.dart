import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:financial_recording/data/services/supabase_service.dart';

class Household {
  const Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final DateTime createdAt;

  factory Household.fromJson(Map<String, dynamic> j) => Household(
        id: j['id'] as String,
        name: j['name'] as String,
        ownerId: j['owner_id'] as String,
        inviteCode: j['invite_code'] as String,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class HouseholdMember {
  const HouseholdMember({
    required this.userId,
    required this.role,
    this.displayName,
    this.email,
    required this.joinedAt,
  });

  final String userId;
  final String role;
  final String? displayName;
  final String? email;
  final DateTime joinedAt;

  bool get isOwner => role == 'owner';

  /// Best human label: chosen name, else the part of the email before @.
  String get label {
    if (displayName != null && displayName!.trim().isNotEmpty) return displayName!;
    if (email != null && email!.contains('@')) return email!.split('@').first;
    return 'Anggota';
  }

  factory HouseholdMember.fromJson(Map<String, dynamic> j) => HouseholdMember(
        userId: j['user_id'] as String,
        role: j['role'] as String,
        displayName: j['display_name'] as String?,
        email: j['email'] as String?,
        joinedAt: DateTime.tryParse(j['joined_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class FamilyException implements Exception {
  const FamilyException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thin client for the household RPCs in the `family_households`
/// migration. All authorization is enforced server-side; this class only
/// shapes the calls and turns Postgres errors into readable messages.
class FamilyService {
  SupabaseClient get _db => SupabaseService.client;

  /// The caller's household and its members, or `(null, [])` when the
  /// caller isn't in one. RLS only ever returns the caller's own household.
  Future<(Household?, List<HouseholdMember>)> fetch() async {
    final rows = await _db.from('households').select().limit(1) as List<dynamic>;
    if (rows.isEmpty) return (null, <HouseholdMember>[]);
    final household = Household.fromJson(Map<String, dynamic>.from(rows.first as Map));
    final memberRows = await _db
        .from('household_members')
        .select()
        .eq('household_id', household.id)
        .order('joined_at') as List<dynamic>;
    final members = memberRows.map((r) => HouseholdMember.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    return (household, members);
  }

  Future<Household> create(String name, {String? displayName}) =>
      _call(() => _db.rpc('create_household', params: {'p_name': name, 'p_display_name': displayName}))
          .then((r) => Household.fromJson(Map<String, dynamic>.from(r as Map)));

  Future<Household> join(String code, {String? displayName}) =>
      _call(() => _db.rpc('join_household', params: {'p_code': code, 'p_display_name': displayName}))
          .then((r) => Household.fromJson(Map<String, dynamic>.from(r as Map)));

  Future<void> leave() => _call(() => _db.rpc('leave_household'));

  Future<void> removeMember(String userId) =>
      _call(() => _db.rpc('remove_household_member', params: {'p_user_id': userId}));

  Future<String> regenerateCode() =>
      _call(() => _db.rpc('regenerate_household_code')).then((r) => r.toString());

  Future<void> update({String? name, String? displayName}) =>
      _call(() => _db.rpc('update_household', params: {'p_name': name, 'p_display_name': displayName}));

  Future<dynamic> _call(Future<dynamic> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      throw FamilyException(e.message);
    } catch (e) {
      final s = e.toString();
      if (s.contains('SocketException') || s.contains('ClientException')) {
        throw const FamilyException('Tidak ada koneksi internet. Coba lagi setelah online.');
      }
      throw FamilyException(s);
    }
  }
}

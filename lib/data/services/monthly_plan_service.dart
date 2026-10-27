import 'dart:convert';
import 'package:financial_recording/util/browser/unsaved_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/data/services/supabase_service.dart';

class PlanSnapshot {
  final MonthlyPlan plan;
  final int revision;
  final bool pending;
  final bool deviceSaved;
  const PlanSnapshot(
    this.plan,
    this.revision, {
    this.pending = false,
    this.deviceSaved = true,
  });
}

/// Separate personal namespace: never part of a shared family ledger.
/// A dirty device copy is retained until an explicit successful CAS save.
class MonthlyPlanService {
  final String uid;
  final SupabaseClient? transport;
  final String? Function()? actor;
  final Future<SharedPreferences> Function()? preferences;
  static final _drafts = <String, PlanSnapshot>{};
  static final _guards = <String, void Function()>{};
  MonthlyPlanService(this.uid, {this.transport, this.actor, this.preferences});
  SupabaseClient get _client => transport ?? SupabaseService.client;
  Future<SharedPreferences> _prefs() =>
      (preferences ?? SharedPreferences.getInstance)();
  void _guard() {
    if ((actor == null ? SupabaseService.currentUser?.id : actor!()) != uid) {
      throw StateError('Akun berubah. Buka ulang rencana.');
    }
  }

  String _key(String period) => 'wallet-personal-plan-v1:$uid:$period';
  Future<PlanSnapshot?> cached(String period) async {
    _guard();
    if (_drafts[_key(period)]?.pending == true ||
        _drafts[_key(period)]?.deviceSaved == false)
      return _drafts[_key(period)];
    final prefs = await _prefs();
    _guard();
    final raw = prefs.getString(_key(period));
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return PlanSnapshot(
      MonthlyPlan.fromJson(Map<String, dynamic>.from(data['data'] as Map)),
      data['revision'] as int,
      pending: data['pending'] == true,
    );
  }

  Future<void> store(String period, PlanSnapshot snapshot) async {
    _guard();
    final key = _key(period);
    _drafts[key] = PlanSnapshot(
      snapshot.plan,
      snapshot.revision,
      pending: snapshot.pending,
      deviceSaved: false,
    );
    if (snapshot.pending) _guards.putIfAbsent(key, warnBeforeClosing);
    final prefs = await _prefs();
    _guard();
    final ok = await prefs.setString(
      _key(period),
      jsonEncode({
        'data': snapshot.plan.toJson(),
        'revision': snapshot.revision,
        'pending': snapshot.pending,
      }),
    );
    if (!ok) {
      throw StateError('Penyimpanan perangkat gagal. Jangan tutup halaman.');
    }
    _guard();
    _drafts[key] = snapshot;
    _guards.remove(key)?.call();
  }

  Future<PlanSnapshot?> remote(String period) async {
    _guard();
    final row = await _client
        .from('personal_monthly_plans')
        .select('data,revision')
        .eq('user_id', uid)
        .eq('period', period)
        .maybeSingle();
    _guard();
    if (row == null) return null;
    return PlanSnapshot(
      MonthlyPlan.fromJson(Map<String, dynamic>.from(row['data'] as Map)),
      row['revision'] as int,
    );
  }

  Future<PlanSnapshot> save(String period, PlanSnapshot snapshot) async {
    _guard();
    final row = await _client.rpc(
      'save_personal_monthly_plan',
      params: {
        'p_period': period,
        'p_expected_revision': snapshot.revision,
        'p_data': snapshot.plan.toJson(),
      },
    );
    _guard();
    final result = PlanSnapshot(snapshot.plan, row as int);
    try {
      await store(period, result);
    } catch (_) {
      _guard();
      _guards.remove(_key(period))?.call();
      return PlanSnapshot(result.plan, result.revision, deviceSaved: false);
    }
    return result;
  }
}

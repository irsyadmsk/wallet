import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/data/services/supabase_service.dart';
import 'package:financial_recording/data/services/sync/sync_entity.dart';
import 'package:financial_recording/data/services/sync/sync_registry.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';

class PullPlan {
  final upserts = <Map<String, dynamic>>[];
  final deletes = <String>[];
  final newHashes = <String, String>{};
  final goneHashes = <String>[];
  String? maxCursor;
}

class SyncResult {
  const SyncResult({required this.pushed, required this.pulled, this.error});
  final int pushed;
  final int pulled;
  final String? error;
  bool get ok => error == null;
}

/// Two-way sync between the local Hive boxes and the `wallet` Supabase
/// project.
///
/// - **Which ledger:** rows live under a *ledger owner* id — the signed-in
///   user, or their household owner once they join a family (see
///   `FamilyService` and the `family_households` migration). Switching
///   ledgers goes through [switchLedger], which never mixes two ledgers in
///   one set of local boxes.
/// - **Push:** only rows whose JSON changed since they were last synced
///   (tracked by a SHA-1 per row), so frequent automatic syncs stay cheap
///   and a pulled row is never echoed straight back.
/// - **Pull:** everything with a server `updated_at` newer than the
///   per-table cursor, which comes from the server clock, not this device's.
/// - **Conflicts:** last writer wins per row.
class SyncService {
  static const _metaBox = 'sync_meta';
  static const _hashBox = 'sync_hashes';
  static const _lastSyncKey = 'lastSyncAt';
  static const _ledgerKey = 'ledgerOwnerId';
  static const _userKey = 'syncedUserId';

  static Future<void> ensureOpen() async {
    if (!Hive.isBoxOpen(_metaBox)) await Hive.openBox<String>(_metaBox);
    if (!Hive.isBoxOpen(_hashBox)) await Hive.openBox<String>(_hashBox);
    await TombstoneService.ensureOpen();
  }

  Box<String> get _meta => Hive.box<String>(_metaBox);
  Box<String> get _hashes => Hive.box<String>(_hashBox);

  DateTime? get lastSyncAt {
    final iso = _meta.get(_lastSyncKey);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  /// The ledger this device currently mirrors, or null before first sync.
  String? get ledgerOwnerId => _meta.get(_ledgerKey);

  /// The account whose data is in the local boxes, or null on a fresh
  /// install / after a wipe.
  String? get syncedUserId => _meta.get(_userKey);

  Future<void> setLedgerOwner(String ownerId) => _meta.put(_ledgerKey, ownerId);

  Future<void> markSyncedUser(String userId) => _meta.put(_userKey, userId);

  Future<SyncResult> syncNow() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      return const SyncResult(pushed: 0, pulled: 0, error: 'Belum login.');
    }
    final ledger = ledgerOwnerId ?? user.id;

    try {
      final pushed = await _pushTombstones(ledger) + await _pushLocal(ledger);
      final pulled = await _pullRemote(ledger);
      await _meta.put(_lastSyncKey, DateTime.now().toIso8601String());
      await _meta.put(_ledgerKey, ledger);
      await _meta.put(_userKey, user.id);
      if (pulled > 0) await LedgerService().recomputeAllBalances();
      return SyncResult(pushed: pushed, pulled: pulled);
    } catch (e) {
      return SyncResult(pushed: 0, pulled: 0, error: _friendly(e));
    }
  }

  /// Moves this device onto [ownerId]'s ledger. When [pushFirst] is true,
  /// the current ledger is synced before the local copy is wiped, so
  /// nothing recorded here is lost (e.g. joining a family keeps your own
  /// ledger safe in the cloud).
  Future<SyncResult> switchLedger(String ownerId, {bool pushFirst = true}) async {
    if (pushFirst && SupabaseService.currentUser != null) {
      final r = await syncNow();
      if (!r.ok) return r;
    }
    await wipeLocal();
    await setLedgerOwner(ownerId);
    return syncNow();
  }

  /// Clears every financial box plus sync bookkeeping. Device preferences
  /// (theme, PIN) are kept.
  Future<void> wipeLocal() async {
    for (final name in [
      AppBoxes.accounts,
      AppBoxes.categories,
      AppBoxes.transactions,
      AppBoxes.tags,
      AppBoxes.budgets,
      AppBoxes.recurring,
      AppBoxes.goals,
      AppBoxes.templates,
      AppBoxes.debts,
      AppBoxes.memos,
    ]) {
      if (Hive.isBoxOpen(name)) await Hive.box(name).clear();
    }
    await _hashes.clear();
    await _meta.clear();
    await TombstoneService().clearAll();
  }

  Future<int> _pushTombstones(String ledger) async {
    final tombstones = TombstoneService().byTable();
    var count = 0;
    for (final entry in tombstones.entries) {
      final rows = entry.value
          .map((id) => {
                'id': id,
                'user_id': ledger,
                'data': <String, dynamic>{},
                'deleted_at': DateTime.now().toUtc().toIso8601String(),
              })
          .toList();
      if (rows.isEmpty) continue;
      await SupabaseService.client.from(entry.key).upsert(rows, onConflict: 'user_id,id');
      for (final id in entry.value) {
        await TombstoneService().clear(entry.key, id);
        await _hashes.delete('${entry.key}:$id');
      }
      count += rows.length;
    }
    return count;
  }

  Future<int> _pushLocal(String ledger) async {
    var count = 0;
    for (final entity in syncEntities) {
      final rows = <Map<String, dynamic>>[];
      final newHashes = <String, String>{};
      for (final item in entity.allItems()) {
        final id = entity.idOf(item);
        final data = entity.toJson(item);
        final h = hashRow(data);
        final key = '${entity.table}:$id';
        if (_hashes.get(key) == h) continue;
        rows.add({'id': id, 'user_id': ledger, 'data': data, 'deleted_at': null});
        newHashes[key] = h;
      }
      if (rows.isEmpty) continue;
      for (var i = 0; i < rows.length; i += 500) {
        final chunk = rows.sublist(i, i + 500 > rows.length ? rows.length : i + 500);
        await SupabaseService.client.from(entity.table).upsert(chunk, onConflict: 'user_id,id');
      }
      await _hashes.putAll(newHashes);
      count += rows.length;
    }
    return count;
  }

  /// Returns how many rows actually changed locally. Our own pushes come
  /// straight back through Realtime; those match the stored hash and are
  /// skipped, so they cost no writes, no balance recompute and no refresh.
  Future<int> _pullRemote(String ledger) async {
    var count = 0;
    for (final entity in syncEntities) {
      final cursorKey = 'cursor:${entity.table}';
      final since = _meta.get(cursorKey);
      var query = SupabaseService.client.from(entity.table).select().eq('user_id', ledger);
      if (since != null) query = query.gt('updated_at', since);
      final rows = await query.order('updated_at') as List<dynamic>;
      final plan = planPull(entity, rows.map((r) => Map<String, dynamic>.from(r as Map)), _hashes.get);
      await entity.applyRemote(plan.upserts, plan.deletes);
      if (plan.newHashes.isNotEmpty) await _hashes.putAll(plan.newHashes);
      if (plan.goneHashes.isNotEmpty) await _hashes.deleteAll(plan.goneHashes);
      if (plan.maxCursor != null && plan.maxCursor != since) await _meta.put(cursorKey, plan.maxCursor!);
      count += plan.upserts.length + plan.deletes.length;
    }
    return count;
  }

  /// Pure planning step of a pull, split out so it can be tested without
  /// Supabase: which rows to write, which to delete, and their new hashes.
  static PullPlan planPull(
    SyncEntity entity,
    Iterable<Map<String, dynamic>> rows,
    String? Function(String key) storedHash,
  ) {
    final plan = PullPlan();
    for (final row in rows) {
      final updated = row['updated_at']?.toString();
      if (updated != null && (plan.maxCursor == null || updated.compareTo(plan.maxCursor!) > 0)) {
        plan.maxCursor = updated;
      }
      final id = row['id'] as String;
      final key = '${entity.table}:$id';
      if (row['deleted_at'] != null) {
        plan.deletes.add(id);
        plan.goneHashes.add(key);
        continue;
      }
      final data = Map<String, dynamic>.from(row['data'] as Map);
      final h = hashRow(entity.normalize(data));
      if (storedHash(key) == h) continue;
      plan.upserts.add(data);
      plan.newHashes[key] = h;
    }
    return plan;
  }

  /// `cachedBalance` is derived (recomputed from the ledger after every
  /// pull), so a balance-only change is not a reason to re-upload a row.
  static String hashRow(Map<String, dynamic> data) {
    final stable = Map<String, dynamic>.from(data)..remove('cachedBalance');
    return sha1.convert(utf8.encode(jsonEncode(stable))).toString();
  }

  static String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Failed host lookup') || s.contains('ClientException')) {
      return 'Tidak ada koneksi. Data tetap aman di perangkat dan akan disinkronkan otomatis.';
    }
    return s;
  }
}

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/data/services/supabase_service.dart';
import 'package:financial_recording/data/services/sync/sync_entity.dart';
import 'package:financial_recording/data/services/sync/ledger_merge.dart';
import 'package:financial_recording/data/services/sync/sync_registry.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';

class PullPlan {
  final upserts = <Map<String, dynamic>>[];
  final deletes = <String>[];
  final newHashes = <String, String>{};
  final goneHashes = <String>[];
  String? maxCursor;
}

/// A transaction another person recorded, seen for the first time in a pull.
class IncomingTx {
  const IncomingTx({required this.by, required this.amount, required this.type, this.memo});
  final String by;
  final int amount;
  final String type;
  final String? memo;
}

class SyncResult {
  const SyncResult({required this.pushed, required this.pulled, this.error, this.incoming = const []});

  /// New transactions recorded by someone else (family members, or this
  /// user on another device is excluded), for a "just arrived" notice.
  final List<IncomingTx> incoming;
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

  /// Hive keys written per table since that table was last pushed, fed by a
  /// box watcher. A table not yet watched in this process (or whose push
  /// failed mid-way) is in [_needsFullScan] and gets one full hash pass.
  static final _dirtyKeys = <String, Set<dynamic>>{};
  static final _needsFullScan = <String>{};
  static final _watchedBoxes = <String, Box>{};

  static void _watch(SyncEntity entity) {
    final box = entity.box?.call();
    if (box == null) return;
    if (identical(_watchedBoxes[entity.table], box)) return;
    _watchedBoxes[entity.table] = box;
    _needsFullScan.add(entity.table);
    box.watch().listen((e) => _dirtyKeys.putIfAbsent(entity.table, () => {}).add(e.key));
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
      _incoming.clear();
      final pulled = await _pullRemote(ledger);
      await _meta.put(_lastSyncKey, DateTime.now().toIso8601String());
      await _meta.put(_ledgerKey, ledger);
      await _meta.put(_userKey, user.id);
      if (pulled > 0) await LedgerService().recomputeAllBalances();
      return SyncResult(pushed: pushed, pulled: pulled, incoming: List.of(_incoming));
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

  /// Copies [fromUserId]'s own cloud ledger into the ledger this device is
  /// on (the family's), mapping shared categories, tags, templates and
  /// unused starter accounts onto the family's — see [LedgerMerge]. Rows
  /// keep their ids, so running it again updates rather than duplicates.
  /// Returns how many rows were written locally; the caller syncs them up.
  Future<int> importLedger(String fromUserId) async {
    final mine = <String, List<Map<String, dynamic>>>{};
    for (final entity in syncEntities) {
      final rows = await _fetchAll(entity.table, fromUserId, null, liveOnly: true);
      mine[entity.table] = [for (final r in rows) Map<String, dynamic>.from(r['data'] as Map)];
    }
    final family = {
      for (final entity in syncEntities) entity.table: [for (final item in entity.allItems()) entity.toJson(item)],
    };
    final plan = LedgerMerge.plan(mine: mine, family: family);
    var written = 0;
    for (final entity in syncEntities) {
      final rows = plan[entity.table];
      if (rows != null && rows.isNotEmpty) written += await entity.applyRemote(rows, const []);
    }
    await LedgerService().recomputeAllBalances();
    await _meta.put('$_importedPrefix$fromUserId', DateTime.now().toIso8601String());
    return written;
  }

  static const _importedPrefix = 'imported:';
  static final _incoming = <IncomingTx>[];

  /// Whether [userId]'s personal ledger was already merged into this one.
  bool hasImported(String userId) => _meta.get('$_importedPrefix$userId') != null;

  /// Clears every financial box plus sync bookkeeping. Device preferences
  /// (theme, PIN) are kept.
  Future<void> wipeLocal() async {
    for (final box in openFinancialBoxes()) {
      await box.clear();
    }
    await _hashes.clear();
    await _meta.clear();
    _dirtyKeys.clear();
    _needsFullScan.addAll(_watchedBoxes.keys);
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
      _watch(entity);
      final table = entity.table;
      final full = entity.itemsAt == null || !_watchedBoxes.containsKey(table) || _needsFullScan.contains(table);
      // Snapshot and reset before any await, so writes made while this push
      // is in flight are tracked for the next one.
      final pending = _dirtyKeys.remove(table) ?? <dynamic>{};
      _needsFullScan.remove(table);
      if (!full && pending.isEmpty) continue;
      try {
        final items = full ? entity.allItems() : entity.itemsAt!(pending);
        final rows = <Map<String, dynamic>>[];
        final newHashes = <String, String>{};
        for (final item in items) {
          final id = entity.idOf(item);
          final data = entity.toJson(item);
          final h = hashRow(data);
          final key = '$table:$id';
          if (_hashes.get(key) == h) continue;
          rows.add({'id': id, 'user_id': ledger, 'data': data, 'deleted_at': null});
          newHashes[key] = h;
        }
        if (rows.isEmpty) continue;
        for (var i = 0; i < rows.length; i += 500) {
          final chunk = rows.sublist(i, i + 500 > rows.length ? rows.length : i + 500);
          await SupabaseService.client.from(table).upsert(chunk, onConflict: 'user_id,id');
        }
        await _hashes.putAll(newHashes);
        count += rows.length;
      } catch (_) {
        if (full) {
          _needsFullScan.add(table);
        } else {
          _dirtyKeys.putIfAbsent(table, () => {}).addAll(pending);
        }
        rethrow;
      }
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
      final rows = await _fetchAll(entity.table, ledger, pullFrom(since));
      final plan = planPull(entity, rows, _hashes.get);
      // Only incremental pulls announce arrivals — a first full pull of a
      // ledger isn't "new" activity.
      if (entity.table == 'transactions' && since != null) {
        final me = SupabaseService.currentUser?.id;
        for (final data in plan.upserts) {
          final by = data['createdBy'];
          if (by == null || by == me || _hashes.get('transactions:${data['id']}') != null) continue;
          _incoming.add(IncomingTx(
            by: data['createdByName']?.toString() ?? 'Anggota keluarga',
            amount: (data['amount'] as num?)?.toInt() ?? 0,
            type: data['type']?.toString() ?? '',
            memo: data['memo'] as String?,
          ));
        }
      }
      // Only ever move the cursor forward (the overlap can return nothing
      // newer than it).
      if (since != null && plan.maxCursor != null && !isAfterCursor(plan.maxCursor!, since)) plan.maxCursor = since;
      final changed = await entity.applyRemote(plan.upserts, plan.deletes);
      if (plan.newHashes.isNotEmpty) await _hashes.putAll(plan.newHashes);
      if (plan.goneHashes.isNotEmpty) await _hashes.deleteAll(plan.goneHashes);
      if (plan.maxCursor != null && plan.maxCursor != since) await _meta.put(cursorKey, plan.maxCursor!);
      count += changed;
    }
    return count;
  }

  /// PostgREST returns at most this many rows per request (Supabase's
  /// default `max_rows`), so every read pages through with `range`.
  static const pageSize = 1000;

  /// Every row of [table] in [ledger] (optionally only those updated since
  /// [from]), paged. Without paging a ledger of more than 1,000 rows reached
  /// a new device only partly — and an import that "replaces all" on such a
  /// device left the rows it never saw behind as duplicates.
  Future<List<Map<String, dynamic>>> _fetchAll(String table, String ledger, String? from, {bool liveOnly = false}) async {
    final out = <Map<String, dynamic>>[];
    for (var offset = 0;; offset += pageSize) {
      var query = SupabaseService.client.from(table).select().eq('user_id', ledger);
      if (from != null) query = query.gte('updated_at', from);
      if (liveOnly) query = query.isFilter('deleted_at', null);
      final page = await query.order('updated_at').order('id').range(offset, offset + pageSize - 1) as List<dynamic>;
      out.addAll(page.map((r) => Map<String, dynamic>.from(r as Map)));
      if (page.length < pageSize) return out;
    }
  }

  /// How far back a pull re-reads before the stored cursor. `updated_at`
  /// is stamped when a write *starts*, so a row committed a moment after
  /// our last pull can carry a timestamp older than the cursor and would be
  /// skipped forever. Re-reading a short window catches it; unchanged rows
  /// match their stored hash and cost nothing.
  static const pullOverlap = Duration(minutes: 2);

  /// Lower bound for the next pull, or null for a full pull.
  static String? pullFrom(String? cursor) {
    if (cursor == null) return null;
    final t = DateTime.tryParse(cursor);
    if (t == null) return cursor;
    return t.toUtc().subtract(pullOverlap).toIso8601String();
  }

  /// Whether server timestamp [a] is later than [b].
  static bool isAfterCursor(String a, String b) {
    final ta = DateTime.tryParse(a), tb = DateTime.tryParse(b);
    if (ta == null || tb == null) return a.compareTo(b) > 0;
    return ta.isAfter(tb);
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

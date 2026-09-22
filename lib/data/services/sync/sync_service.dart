import 'package:hive/hive.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/data/services/supabase_service.dart';
import 'package:financial_recording/data/services/sync/sync_entity.dart';
import 'package:financial_recording/data/services/sync/sync_registry.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';

class SyncResult {
  const SyncResult({required this.pushed, required this.pulled, this.error});
  final int pushed;
  final int pulled;
  final String? error;
  bool get ok => error == null;
}

/// Two-way sync between the local Hive boxes and the `wallet` Supabase
/// project. Policy is deliberately simple for a single-user, multi-device
/// app: push local state first (server stamps `updated_at`), then pull
/// everything changed since the last sync — so the most recently synced
/// device's edits win on a given record. Good enough without a real
/// conflict UI; see [syncEntities] for what's excluded.
class SyncService {
  static const _metaBox = 'sync_meta';
  static const _lastSyncKey = 'lastSyncAt';

  static Future<void> ensureOpen() async {
    if (!Hive.isBoxOpen(_metaBox)) {
      await Hive.openBox<String>(_metaBox);
    }
    await TombstoneService.ensureOpen();
  }

  Box<String> get _meta => Hive.box<String>(_metaBox);

  DateTime? get lastSyncAt {
    final iso = _meta.get(_lastSyncKey);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  Future<SyncResult> syncNow() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      return const SyncResult(pushed: 0, pulled: 0, error: 'Belum login.');
    }

    try {
      final pushed = await _pushTombstones(user.id) + await _pushLocal(user.id);
      final pulled = await _pullRemote(user.id);
      await _meta.put(_lastSyncKey, DateTime.now().toIso8601String());
      await LedgerService().recomputeAllBalances();
      return SyncResult(pushed: pushed, pulled: pulled);
    } catch (e) {
      return SyncResult(pushed: 0, pulled: 0, error: e.toString());
    }
  }

  Future<int> _pushTombstones(String userId) async {
    final tombstones = TombstoneService().byTable();
    var count = 0;
    for (final entry in tombstones.entries) {
      final rows = entry.value
          .map((id) => {
                'id': id,
                'user_id': userId,
                'data': <String, dynamic>{},
                'deleted_at': DateTime.now().toIso8601String(),
              })
          .toList();
      if (rows.isEmpty) continue;
      await SupabaseService.client.from(entry.key).upsert(rows, onConflict: 'user_id,id');
      for (final id in entry.value) {
        await TombstoneService().clear(entry.key, id);
      }
      count += rows.length;
    }
    return count;
  }

  Future<int> _pushLocal(String userId) async {
    var count = 0;
    for (final entity in syncEntities) {
      final items = entity.allItems();
      if (items.isEmpty) continue;
      final rows = items
          .map((item) => {
                'id': entity.idOf(item),
                'user_id': userId,
                'data': entity.toJson(item),
                'deleted_at': null,
              })
          .toList();
      await SupabaseService.client.from(entity.table).upsert(rows, onConflict: 'user_id,id');
      count += rows.length;
    }
    return count;
  }

  Future<int> _pullRemote(String userId) async {
    var count = 0;
    final since = lastSyncAt;
    for (final entity in syncEntities) {
      var query = SupabaseService.client.from(entity.table).select().eq('user_id', userId);
      if (since != null) {
        query = query.gt('updated_at', since.toIso8601String());
      }
      final rows = await query as List<dynamic>;
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw as Map);
        _applyRemoteRow(entity, row);
        count++;
      }
    }
    return count;
  }

  void _applyRemoteRow(SyncEntity entity, Map<String, dynamic> row) {
    final id = row['id'] as String;
    final deletedAt = row['deleted_at'];

    if (deletedAt != null) {
      entity.deleteLocal(id);
      return;
    }

    final data = Map<String, dynamic>.from(row['data'] as Map);
    entity.upsertLocal(data);
  }
}

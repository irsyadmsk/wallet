import 'package:hive/hive.dart';

/// Records local deletions so [SyncService] can propagate them to Supabase
/// as soft-deletes (`deleted_at`) instead of silently disappearing on other
/// devices. Repositories call [record] from their `delete`/`remove` method;
/// no Hive adapter needed since entries are plain strings.
class TombstoneService {
  static const boxName = 'sync_tombstones';

  Box<String> get _box => Hive.box<String>(boxName);

  static Future<void> ensureOpen() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<String>(boxName);
    }
  }

  Future<void> record(String table, String id) async {
    await ensureOpen();
    await _box.put('$table:$id', DateTime.now().toIso8601String());
  }

  Map<String, List<String>> byTable() {
    final result = <String, List<String>>{};
    for (final key in _box.keys.cast<String>()) {
      final parts = key.split(':');
      if (parts.length < 2) continue;
      final table = parts.first;
      final id = parts.sublist(1).join(':');
      result.putIfAbsent(table, () => []).add(id);
    }
    return result;
  }

  Future<void> clear(String table, String id) => _box.delete('$table:$id');
}

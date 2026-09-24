/// Bridges one Hive box to one Supabase table for [SyncService], reusing
/// each model's existing `toJson`/`fromJson` instead of a parallel SQL
/// schema — see the `create_sync_tables` migration on the `wallet` project.
///
/// Non-generic by design: the concrete Hive type only exists inside the
/// closures built by `syncEntityFor<T>` in `sync_registry.dart`, so a single
/// `List<SyncEntity>` can hold every entity without hitting Dart's
/// generic-class invariance.
class SyncEntity {
  const SyncEntity({
    required this.table,
    required this.allItems,
    required this.toJson,
    required this.idOf,
    required this.normalize,
    required this.applyRemote,
  });

  final String table;
  final List<dynamic> Function() allItems;
  final Map<String, dynamic> Function(dynamic item) toJson;
  final String Function(dynamic item) idOf;

  /// Round-trips remote `data` through the model (`fromJson` → `toJson`), so
  /// its hash matches what [toJson] produces for the same row locally.
  /// Postgres `jsonb` reorders keys, so hashing the raw remote map would
  /// make every pulled row look edited and get pushed straight back.
  final Map<String, dynamic> Function(Map<String, dynamic> data) normalize;

  /// Writes a whole pull batch in one pass: upserts by id, deletes by id.
  final Future<void> Function(List<Map<String, dynamic>> upserts, List<String> deletes) applyRemote;
}

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
    required this.upsertLocal,
    required this.deleteLocal,
  });

  final String table;
  final List<dynamic> Function() allItems;
  final Map<String, dynamic> Function(dynamic item) toJson;
  final String Function(dynamic item) idOf;
  final void Function(Map<String, dynamic> data) upsertLocal;
  final void Function(String id) deleteLocal;
}

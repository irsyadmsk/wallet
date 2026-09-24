import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/tx_model/tx_item_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/services/sync/sync_registry.dart';
import 'package:financial_recording/data/services/sync/sync_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

/// Postgres `jsonb` stores object keys sorted by length, then bytewise.
Map<String, dynamic> jsonbOrder(Map<String, dynamic> m) {
  final keys = m.keys.toList()
    ..sort((a, b) => a.length != b.length ? a.length.compareTo(b.length) : a.compareTo(b));
  return {for (final k in keys) k: m[k]};
}

TxModel tx(int i) => TxModel(
      id: 'tx-$i',
      type: TxType.expense,
      amount: 1000 + i,
      accountId: 'acc',
      categoryId: 'cat',
      date: DateTime(2026, 1, 1).add(Duration(hours: i)),
      memo: 'catatan $i',
    );

void main() {
  final entity = syncEntities.firstWhere((e) => e.table == 'transactions');

  setUp(() async {
    Hive.init('./.dart_tool/hive_test_sync_pull');
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(TxTypeAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(TxItemModelAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(TxModelAdapter());
    await Hive.openBox<TxModel>(AppBoxes.transactions);
    await Hive.box<TxModel>(AppBoxes.transactions).clear();
  });
  tearDown(() async => Hive.close());

  test('baris sendiri yang kembali dari server (kunci diurut ulang jsonb) tidak dianggap berubah', () {
    final local = entity.toJson(tx(1));
    final serverData = jsonbOrder(jsonDecode(jsonEncode(local)) as Map<String, dynamic>);
    // Akar masalah lama: hash mentah data server berbeda dari hash lokal.
    expect(SyncService.hashRow(serverData), isNot(SyncService.hashRow(local)));

    final stored = {'transactions:tx-1': SyncService.hashRow(local)};
    final plan = SyncService.planPull(
      entity,
      [{'id': 'tx-1', 'data': serverData, 'deleted_at': null, 'updated_at': '2026-09-24T10:00:00Z'}],
      (k) => stored[k],
    );
    expect(plan.upserts, isEmpty, reason: 'gema push sendiri tidak ditulis ulang');
    expect(plan.maxCursor, '2026-09-24T10:00:00Z');
  });

  test('perubahan dari perangkat lain tetap diterapkan, dan hash-nya cocok dengan push berikutnya', () async {
    final changed = tx(2)..amount = 99999;
    final serverData = jsonbOrder(jsonDecode(jsonEncode(entity.toJson(changed))) as Map<String, dynamic>);
    final plan = SyncService.planPull(
      entity,
      [{'id': 'tx-2', 'data': serverData, 'deleted_at': null, 'updated_at': '2026-09-24T10:00:01Z'}],
      (_) => 'hash-lama',
    );
    expect(plan.upserts, hasLength(1));
    await entity.applyRemote(plan.upserts, plan.deletes);
    final stored = Hive.box<TxModel>(AppBoxes.transactions).values.single;
    expect(stored.amount, 99999);
    // Push berikutnya menghitung hash dari toJson lokal: harus sama → tidak diunggah ulang.
    expect(SyncService.hashRow(entity.toJson(stored)), plan.newHashes['transactions:tx-2']);
  });

  test('menarik 5.000 baris ke kotak berisi 5.000 baris selesai cepat (bukan n²)', () async {
    final box = Hive.box<TxModel>(AppBoxes.transactions);
    await box.addAll([for (var i = 0; i < 5000; i++) tx(i)]);
    final rows = [
      for (var i = 0; i < 5000; i++)
        {'id': 'tx-$i', 'data': jsonbOrder(entity.toJson(tx(i)..amount = 7)), 'deleted_at': null, 'updated_at': 't$i'},
      {'id': 'tx-baru', 'data': entity.toJson(tx(9000)..id = 'tx-baru'), 'deleted_at': null, 'updated_at': 'u'},
      {'id': 'tx-0', 'data': null, 'deleted_at': '2026-09-24', 'updated_at': 'v'},
    ];
    final sw = Stopwatch()..start();
    final plan = SyncService.planPull(entity, rows.where((r) => r['id'] != 'tx-0' || r['deleted_at'] != null), (_) => null);
    await entity.applyRemote(plan.upserts, plan.deletes);
    sw.stop();
    expect(box.length, 5000); // 5000 - 1 dihapus + 1 baru
    expect(box.values.where((t) => t.id == 'tx-0'), isEmpty);
    expect(box.values.firstWhere((t) => t.id == 'tx-10').amount, 7);
    expect(sw.elapsedMilliseconds, lessThan(3000), reason: 'butuh ${sw.elapsedMilliseconds} ms');
  });
}

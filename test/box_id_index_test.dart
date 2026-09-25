import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/tx_model/tx_item_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/sync/sync_registry.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

TxModel tx(String id, {int amount = 1000}) => TxModel(
      id: id,
      type: TxType.expense,
      amount: amount,
      accountId: 'acc',
      categoryId: 'cat',
      date: DateTime(2026, 1, 1),
    );

void main() {
  setUp(() async {
    Hive.init('./.dart_tool/hive_test_box_id_index');
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(TxTypeAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(TxItemModelAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(TxModelAdapter());
    await Hive.openBox<TxModel>(AppBoxes.transactions);
    await Hive.box<TxModel>(AppBoxes.transactions).clear();
  });
  tearDown(() async => Hive.close());

  test('byId tetap benar setelah tambah, ubah, dan hapus tanpa jeda', () async {
    final repo = TxRepository();
    await repo.put(tx('a'));
    await repo.put(tx('b'));
    expect(repo.byId('a')?.id, 'a');
    expect(repo.byId('zzz'), isNull);

    // Hapus lalu tambah: panjang box sama, indeks lama tidak boleh dipakai.
    await repo.remove('a');
    await repo.put(tx('c'));
    expect(repo.byId('a'), isNull);
    expect(repo.byId('c')?.id, 'c');

    // Menyimpan ulang id yang sama menimpa, bukan menambah baris.
    await repo.put(tx('b', amount: 5));
    expect(repo.all().where((t) => t.id == 'b').length, 1);
    expect(repo.byId('b')?.amount, 5);
  });

  test('box langsung diubah (seperti pull sync) tetap terbaca lewat byId', () async {
    final repo = TxRepository();
    await repo.put(tx('a'));
    expect(repo.byId('a')?.id, 'a');
    await Hive.box<TxModel>(AppBoxes.transactions).addAll([tx('x'), tx('y')]);
    expect(repo.byId('y')?.id, 'y');
    await repo.put(tx('y', amount: 7));
    expect(repo.all().length, 3);
  });

  test('kotak keuangan bisa diambil tanpa tipe tanpa HiveError', () {
    // `Hive.box(name)` tanpa tipe melempar HiveError untuk kotak bertipe;
    // auto-sync dan wipe saat keluar dulu gagal karena itu.
    final names = openFinancialBoxes().map((b) => b.name).toList();
    expect(names, contains(AppBoxes.transactions.toLowerCase()));
  });
}

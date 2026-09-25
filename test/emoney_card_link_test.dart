import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_item_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/emoney_card_link.dart';
import 'package:financial_recording/data/services/emoney_nfc_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

void _reg<T>(int id, TypeAdapter<T> a) {
  if (!Hive.isAdapterRegistered(id)) Hive.registerAdapter(a);
}

const card = EmoneyCardResult(cardName: 'E-Money', cardNumber: '6032982712229721', balance: '10500', cardCode: 'emo');

void main() {
  setUp(() async {
    Hive.init('./.dart_tool/hive_test_emoney');
    _reg(12, TxTypeAdapter());
    _reg(4, AccountModelAdapter());
    _reg(5, TxCategoryModelAdapter());
    _reg(7, TxItemModelAdapter());
    _reg(6, TxModelAdapter());
    await Hive.openBox<AccountModel>(AppBoxes.accounts);
    await Hive.openBox<TxCategoryModel>(AppBoxes.categories);
    await Hive.openBox<TxModel>(AppBoxes.transactions);
    await Hive.openBox<String>(AppBoxes.nfcScans);
    for (final b in [Hive.box<AccountModel>(AppBoxes.accounts), Hive.box<TxModel>(AppBoxes.transactions), Hive.box<String>(AppBoxes.nfcScans)]) {
      await b.clear();
    }
    await Hive.box<TxCategoryModel>(AppBoxes.categories).clear();
    await Hive.box<TxCategoryModel>(AppBoxes.categories).addAll([
      TxCategoryModel(id: 'lain-keluar', name: 'Lainnya', typeCode: 1),
      TxCategoryModel(id: 'lain-masuk', name: 'Lainnya', typeCode: 0),
    ]);
  });
  tearDown(() async => Hive.close());

  test('nomor kartu dinormalisasi dan diformat per 4 digit', () {
    expect(EmoneyCardLink.formatNumber('6032982712229721'), '6032 9827 1222 9721');
    expect(EmoneyCardLink.normalize('6032 9827-1222 9721'), '6032982712229721');
    expect(card.balanceAmount, 10500);
  });

  test('riwayat cek saldo menyimpan urutan terbaru dan cek sebelumnya', () async {
    final link = EmoneyCardLink();
    await link.record(EmoneyScan(cardCode: 'emo', cardName: 'E-Money', cardNumber: card.cardNumber, balance: 15000, at: DateTime(2026, 9, 18)));
    expect(link.previousOf('6032 9827 1222 9721')!.balance, 15000);
    await link.record(EmoneyScan(cardCode: 'emo', cardName: 'E-Money', cardNumber: card.cardNumber, balance: 10500, at: DateTime(2026, 9, 25)));
    expect(link.history().map((s) => s.balance), [10500, 15000]);
  });

  test('kartu disimpan sebagai akun lalu dikenali saat dipindai lagi', () async {
    final link = EmoneyCardLink();
    final acc = await link.createAccount(card);
    expect(acc.cachedBalance, 10500);
    expect(link.accountFor('6032 9827 1222 9721')?.id, acc.id);
  });

  test('menyamakan saldo mencatat pemakaian sebagai pengeluaran', () async {
    final link = EmoneyCardLink();
    await AccountRepository().upsert(AccountModel(id: 'kartu', name: 'e-Money', groupCode: 6, openingBalance: 15000, cachedBalance: 15000));
    final diff = await link.reconcile(AccountRepository().byId('kartu')!, 10500);
    expect(diff, -4500);
    final tx = TxRepository().all().single;
    expect(tx.type, TxType.expense);
    expect(tx.amount, 4500);
    expect(tx.categoryId, 'lain-keluar');
    expect(AccountRepository().byId('kartu')!.cachedBalance, 10500);
    expect(await link.reconcile(AccountRepository().byId('kartu')!, 10500), 0);
  });
}

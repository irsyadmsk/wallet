import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_item_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/recurring_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/recurring_service.dart';
import 'package:financial_recording/data/services/sync/sync_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

void _registerOnce<T>(int typeId, TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
}

RecurringRuleModel salary() => RecurringRuleModel(
      id: 'gaji',
      type: TxType.income,
      amount: 7500000,
      accountId: 'bank',
      categoryId: 'cat-gaji',
      startDate: DateTime(2026, 7, 1),
    );

void main() {
  group('transaksi berulang', () {
    setUp(() async {
      Hive.init('./.dart_tool/hive_test_recurring');
      _registerOnce(12, TxTypeAdapter());
      _registerOnce(14, RecurrenceFreqAdapter());
      _registerOnce(4, AccountModelAdapter());
      _registerOnce(7, TxItemModelAdapter());
      _registerOnce(6, TxModelAdapter());
      _registerOnce(10, RecurringRuleModelAdapter());
      await Hive.openBox<AccountModel>(AppBoxes.accounts);
      await Hive.openBox<TxModel>(AppBoxes.transactions);
      await Hive.openBox<RecurringRuleModel>(AppBoxes.recurring);
      await Hive.box<AccountModel>(AppBoxes.accounts).clear();
      await Hive.box<TxModel>(AppBoxes.transactions).clear();
      await Hive.box<RecurringRuleModel>(AppBoxes.recurring).clear();
      await AccountRepository().upsert(AccountModel(id: 'bank', name: 'Bank', groupCode: 1));
    });
    tearDown(() async => Hive.close());

    test('mengejar tiap bulan yang terlewat, sekali per bulan', () async {
      await RecurringRepository().upsert(salary());
      final posted = await RecurringService().catchUp(DateTime(2026, 9, 25));
      expect(posted, 3); // 1 Jul, 1 Agu, 1 Sep
      expect(TxRepository().all().map((t) => t.id), unorderedEquals([
        'rec-gaji-20260701', 'rec-gaji-20260801', 'rec-gaji-20260901',
      ]));
      expect(AccountRepository().byId('bank')!.cachedBalance, 3 * 7500000);
    });

    test('perangkat kedua dengan aturan lama tidak mencatat gaji dua kali', () async {
      // Perangkat lain sudah memposting September dan tersinkron ke sini,
      // tapi aturan di perangkat ini belum ikut maju.
      final rule = salary()..nextRunDate = DateTime(2026, 9, 1);
      await RecurringRepository().upsert(rule);
      await TxRepository().put(TxModel(
        id: RecurringService.occurrenceId('gaji', DateTime(2026, 9, 1)),
        type: TxType.income,
        amount: 7500000,
        accountId: 'bank',
        categoryId: 'cat-gaji',
        date: DateTime(2026, 9, 1),
      ));

      final posted = await RecurringService().catchUp(DateTime(2026, 9, 25));

      expect(posted, 0);
      expect(TxRepository().all(), hasLength(1));
      expect(RecurringRepository().byId('gaji')!.nextRunDate, DateTime(2026, 10, 1));
    });
  });

  group('kursor tarik sinkronisasi', () {
    test('menarik ulang jendela singkat sebelum kursor', () {
      final from = SyncService.pullFrom('2026-09-25T10:00:00.000+00:00')!;
      expect(DateTime.parse(from), DateTime.utc(2026, 9, 25, 9, 58));
      expect(SyncService.pullFrom(null), isNull);
    });

    test('kursor hanya maju', () {
      expect(SyncService.isAfterCursor('2026-09-25T10:00:01+00:00', '2026-09-25T10:00:00+00:00'), isTrue);
      expect(SyncService.isAfterCursor('2026-09-25T09:59:00+00:00', '2026-09-25T10:00:00+00:00'), isFalse);
    });
  });
}

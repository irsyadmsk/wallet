import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/app_settings_model/app_settings_model.dart';
import 'package:financial_recording/data/models/budget_model/budget_model.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/models/tag_model/tag_model.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_item_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/presentation/form_tx/view/quick_tx_sheet.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_theme.dart';

void _registerOnce<T>(int typeId, TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
}

Future<void> _openBoxes() async {
  Hive.init('./.dart_tool/hive_test_quick_tx');
  _registerOnce(12, TxTypeAdapter());
  _registerOnce(13, BudgetPeriodAdapter());
  _registerOnce(14, RecurrenceFreqAdapter());
  _registerOnce(4, AccountModelAdapter());
  _registerOnce(5, TxCategoryModelAdapter());
  _registerOnce(7, TxItemModelAdapter());
  _registerOnce(6, TxModelAdapter());
  _registerOnce(8, TagModelAdapter());
  _registerOnce(9, BudgetModelAdapter());
  _registerOnce(10, RecurringRuleModelAdapter());
  _registerOnce(11, AppSettingsModelAdapter());
  await Hive.openBox<AccountModel>(AppBoxes.accounts);
  await Hive.openBox<TxCategoryModel>(AppBoxes.categories);
  await Hive.openBox<TxModel>(AppBoxes.transactions);
  await Hive.openBox<TagModel>(AppBoxes.tags);
  await Hive.openBox<BudgetModel>(AppBoxes.budgets);
  await Hive.openBox<RecurringRuleModel>(AppBoxes.recurring);
  await Hive.openBox<AppSettingsModel>(AppBoxes.settings);
}

TxCategoryModel _cat(String id, {int order = 0, bool archived = false}) =>
    TxCategoryModel(id: id, name: id, typeCode: 1, orderSeq: order, isArchived: archived);

TxModel _tx(String categoryId) => TxModel(
      id: 'tx-$categoryId-${DateTime.now().microsecondsSinceEpoch}',
      type: TxType.expense,
      amount: 1000,
      accountId: 'a',
      categoryId: categoryId,
      date: DateTime.now(),
    );

void main() {
  group('quickCategories', () {
    final roots = [_cat('makan'), _cat('transport', order: 1), _cat('belanja', order: 2)];
    final byId = {for (final c in roots) c.id: c, 'lama': _cat('lama', archived: true)};

    test('most used first, then the remaining roots, without repeats', () {
      final out = quickCategories(
        recent: [_tx('belanja'), _tx('belanja'), _tx('transport'), _tx('lama'), _tx('hilang')],
        roots: roots,
        byId: (id) => byId[id],
      );
      expect(out.map((c) => c.id), ['belanja', 'transport', 'makan']);
    });

    test('respects the limit', () {
      final out = quickCategories(recent: const [], roots: roots, byId: (id) => byId[id], limit: 2);
      expect(out.map((c) => c.id), ['makan', 'transport']);
    });
  });

  group('sheet', () {
    final accounts = AccountRepository();

    setUp(() async {
      await _openBoxes();
      await accounts.clear();
      await Hive.box<TxModel>(AppBoxes.transactions).clear();
      await TxCategoryRepository().clear();
      await accounts.upsert(AccountModel(id: 'a', name: 'Dompet', groupCode: 1));
      await TxCategoryRepository().upsert(_cat('Makan'));
    });

    tearDown(() async => Hive.close());

    for (final scale in [1.0, 1.5]) {
      testWidgets('keypad, category and save record an expense (text scale $scale)', (t) async {
        t.view.physicalSize = const Size(360, 760);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(MaterialApp(
          theme: AppTheme.light(AppColors.defaultSeed),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
            child: child!,
          ),
          home: const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: QuickTxSheet())),
        ));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);

        // Nothing typed yet: saving is not offered.
        expect(t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Simpan')).onPressed, isNull);

        for (final key in ['2', '6', '<', '5', '000']) {
          await t.tap(find.byKey(ValueKey('quick-key-$key')));
          await t.pump();
        }
        expect(find.text('Rp 25.000'), findsOneWidget);

        await t.ensureVisible(find.text('Makan'));
        await t.tap(find.text('Makan'));
        await t.pump();
        // Saving chains several real Hive file writes; run the whole tap in the
        // real-async zone so every continuation can complete.
        await t.runAsync(() async {
          await t.tap(find.widgetWithText(FilledButton, 'Simpan'));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        });
        await t.pump();

        final saved = Hive.box<TxModel>(AppBoxes.transactions).values.toList();
        expect(saved, hasLength(1));
        expect(saved.single.type, TxType.expense);
        expect(saved.single.amount, 25000);
        expect(saved.single.accountId, 'a');
        expect(saved.single.categoryId, 'Makan');
        expect(accounts.byId('a')!.cachedBalance, -25000);
        expect(t.takeException(), isNull);
      }, timeout: const Timeout(Duration(seconds: 90)));
    }
  });
}

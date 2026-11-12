import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/repositories/account_group_repository.dart';
import 'package:financial_recording/domain/account_presets.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';
import 'package:financial_recording/presentation/accounts/widget/account_editor_sheet.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_theme.dart';
import 'package:financial_recording/shared/widget/account_avatar.dart';
import 'package:financial_recording/shared/widget/bank_logo_picker.dart';
import 'package:financial_recording/util/db_service/db_service.dart';

void main() {
  // QButton's double-tap guard keeps the last tap time in SharedPreferences
  // behind a cached instance. Reset both, or a Simpan tap that lands within
  // 500 ms of the previous test's tap is swallowed as a double tap.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DBService.prefs = null;
  });

  test('e-wallet is a built-in group with a stable, unique code', () {
    expect(AccountGroupType.ewallet.code, 14);
    expect(AccountGroupType.fromCode(14), AccountGroupType.ewallet);
    final codes = AccountGroupType.values.map((g) => g.code).toList();
    expect(codes.toSet().length, codes.length);
    expect(AccountGroupType.displayOrder.toSet(), AccountGroupType.values.toSet());
    expect(AccountGroupRepository().of(14).label, 'Dompet Digital');
    expect(AccountGroupType.ewallet.isLiabilityDefault, isFalse);
  });

  test('presets point at bundled logos or fall back to a monogram', () {
    for (final p in accountPresets) {
      if (p.logo != null) expect(bankLogoAssets, contains(p.logo), reason: p.name);
    }
    final names = accountPresetsFor(AccountGroupType.ewallet.code).map((p) => p.name);
    expect(names, containsAll(['GoPay', 'OVO', 'DANA', 'JakOne Pay']));
    expect(accountPresetsFor(AccountGroupType.bank.code).map((p) => p.name),
      containsAll(['Bank DKI', 'Bank Jakarta']));
    expect(accountPresetsFor(AccountGroupType.cash.code), isEmpty);
    expect(accountMonogram('JakOne Pay'), 'JP');
    expect(accountMonogram('  Bank   DKI '), 'BD');
    expect(accountMonogram('ovo'), 'OV');
    expect(accountMonogram(''), '');
  });

  testWidgets('accounts without a logo show initials only for banks and e-wallets',
      (t) async {
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(AppColors.defaultSeed),
      home: Scaffold(body: Row(children: [
        AccountAvatar(account: AccountModel(id: 'a', name: 'JakOne Pay',
          groupCode: AccountGroupType.ewallet.code, colorValue: 0xFFC8102E)),
        AccountAvatar(account: AccountModel(id: 'b', name: 'Dompet saku',
          groupCode: AccountGroupType.cash.code)),
      ]))));
    expect(find.text('JP'), findsOneWidget);
    expect(find.text('DS'), findsNothing);
    expect(t.takeException(), isNull);
  });

  for (final width in [320.0, 1100.0]) {
    testWidgets('quick picks fill a new e-wallet at $width', (t) async {
      t.view.physicalSize = Size(width, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      AccountEditorResult? result;
      await t.pumpWidget(MaterialApp(theme: AppTheme.light(AppColors.defaultSeed),
        home: Builder(builder: (context) => Scaffold(body: Center(child: TextButton(
          onPressed: () async => result = await showModalBottomSheet<AccountEditorResult>(
            context: context, isScrollControlled: true,
            builder: (_) => const AccountEditorSheet()),
          child: const Text('buka')))))));
      await t.tap(find.text('buka'));
      await t.pumpAndSettle();
      expect(find.text('Pilihan cepat'), findsNothing);
      await t.tap(find.textContaining('Tunai').first);
      await t.pumpAndSettle();
      await t.tap(find.textContaining('Dompet Digital').last);
      await t.pumpAndSettle();
      expect(find.text('Pilihan cepat'), findsOneWidget);
      await t.tap(find.widgetWithText(ChoiceChip, 'JakOne Pay'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Simpan'));
      await t.tap(find.text('Simpan'));
      await t.pump(const Duration(seconds: 1));
      await t.pumpAndSettle();
      expect(result?.saved?.name, 'JakOne Pay');
      expect(result?.saved?.groupCode, 14);
      expect(result?.saved?.iconPath, isNull);
      expect(result?.saved?.colorValue, 0xFFC8102E);
      expect(t.takeException(), isNull);
    });
  }
}

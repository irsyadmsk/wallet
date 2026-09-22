import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';
import 'package:financial_recording/shared/widget/bank_card_tile.dart';

void main() {
  testWidgets('BankCardTile displays account name and balance', (WidgetTester tester) async {
    final account = AccountModel(
      id: 'acc_1',
      name: 'BCA Utama',
      groupCode: AccountGroupType.bank.code,
      cachedBalance: 5000000,
      openingBalance: 5000000,
      colorValue: 0xFF0D9488,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BankCardTile(account: account),
      ),
    ));

    expect(find.text('BCA Utama'), findsOneWidget);
    expect(find.text('Bank'), findsOneWidget);
  });
}

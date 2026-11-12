import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_theme.dart';
import 'package:financial_recording/shared/widget/wallet_flow_cards.dart';

void main() {
  for (final width in [280.0, 390.0, 560.0, 1024.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('cash flow fits $width at text scale $scale', (t) async {
        t.view.physicalSize = Size(width, 1000);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(MaterialApp(
          theme: AppTheme.light(AppColors.defaultSeed),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale), disableAnimations: true),
            child: child!),
          home: const Scaffold(body: SingleChildScrollView(
            child: Padding(padding: EdgeInsets.all(16),
              child: WalletFlowCards(income: 123456789000, expense: 98765432100)))),
        ));
        await t.pumpAndSettle();
        expect(find.text('Pemasukan'), findsOneWidget);
        expect(find.text('Pengeluaran'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }
  testWidgets('privacy hides both totals after switching state', (t) async {
    bool hidden = false;
    late StateSetter update;
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.dark(AppColors.defaultSeed),
      home: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return Scaffold(body: WalletFlowCards(income: 7654321,
          expense: 1234567, hidden: hidden));
      }),
    ));
    await t.pumpAndSettle();
    expect(find.text('Rp ••••••'), findsNothing);
    update(() => hidden = true);
    await t.pumpAndSettle();
    expect(find.text('Rp ••••••'), findsNWidgets(2));
    expect(find.textContaining('7.654.321'), findsNothing);
    expect(find.textContaining('1.234.567'), findsNothing);
    expect(t.takeException(), isNull);
  });
}

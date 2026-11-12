import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/presentation/monthly/plan_item_sheet.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_theme.dart';

void main() {
  for (final kind in ['fixed', 'subscription', 'saving']) {
    for (final scenario in [(320.0, 1.5), (1100.0, 1.0)]) {
      testWidgets('$kind form fits ${scenario.$1} with scale ${scenario.$2}', (t) async {
        t.view.physicalSize = Size(scenario.$1, 1000);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(MaterialApp(theme: AppTheme.light(AppColors.defaultSeed),
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scenario.$2)), child: child!),
          home: Scaffold(body: PlanItemSheet(group: 'Rutin', fx: 18000,
            item: AllocationItem(id: 'fixture', group: 'Contoh', name: 'Pos contoh',
              amount: 1000, rule: kind == 'fixed' ? null : PlanRule(kind: kind,
                currency: 'USD', price: 324, taxBps: 1100, months: 12,
                target: 1000, weight: 50, priority: 1)))),
        ));
        await t.pumpAndSettle();
        await t.ensureVisible(find.text('Terapkan'));
        await t.pumpAndSettle();
        expect(find.text('Ubah pos'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }
}

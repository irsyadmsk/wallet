import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/data/services/monthly_plan_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('personal cache cannot appear under another actor; logout denies read and write', () async {
    String? actor = 'synthetic-a';
    final a = MonthlyPlanService('synthetic-a', actor: () => actor);
    await a.store('2026-10', PlanSnapshot(MonthlyPlan(gross: 100), 1, pending: true));
    actor = 'synthetic-b';
    final b = MonthlyPlanService('synthetic-b', actor: () => actor);
    expect(await b.cached('2026-10'), isNull);
    await expectLater(a.cached('2026-10'), throwsStateError);
    await expectLater(a.store('2026-10', PlanSnapshot(MonthlyPlan(), 1)), throwsStateError);
    actor = null; await expectLater(b.cached('2026-10'), throwsStateError);
    actor = 'synthetic-a'; expect((await a.cached('2026-10'))!.plan.gross, 100);
  });
  test('actor changing while preferences open cannot apply late data', () async {
    String? actor = 'slow-a';
    final pending = Completer<SharedPreferences>();
    final a = MonthlyPlanService('slow-a', actor: () => actor, preferences: () => pending.future);
    final read = a.cached('2026-11');
    actor = 'slow-b'; pending.complete(await SharedPreferences.getInstance());
    await expectLater(read, throwsStateError);
  });
  test('failed device storage retains RAM draft when reopening same personal plan', () async {
    final a = MonthlyPlanService('quota-a', actor: () => 'quota-a', preferences: () async => throw StateError('Synthetic quota'));
    final plan = PlanSnapshot(MonthlyPlan(gross: 77), 3, pending: true);
    await expectLater(a.store('2026-12', plan), throwsStateError);
    expect((await a.cached('2026-12'))!.plan.gross, 77);
  });
}

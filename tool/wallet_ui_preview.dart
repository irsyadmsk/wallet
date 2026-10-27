// Local synthetic component-integration preview; never a release entrypoint.
// No Supabase initialization, credentials, production reads or writes.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:financial_recording/app/sync_controller.dart';
import 'package:financial_recording/data/services/family_service.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/data/services/monthly_plan_service.dart';
import 'package:financial_recording/presentation/auth/controller/auth_controller.dart';
import 'package:financial_recording/presentation/monthly/monthly_plan_view.dart';
import 'package:financial_recording/shared/responsive/adaptive_scaffold.dart';
import 'package:financial_recording/shared/theme/app_theme.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';

class PreviewAuth extends GetxController implements AuthController {
  @override
  String get displayName => 'Pengguna Demo';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PreviewSync extends GetxController implements SyncController {
  @override
  final syncing = false.obs;
  @override
  final errorText = RxnString('Pratinjau tanpa server');
  @override
  final household = Rxn<Household>();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PreviewPlans extends MonthlyPlanService {
  PreviewPlans() : super('synthetic-preview') {
    server['template'] = PlanSnapshot(
      MonthlyPlan(
        gross: 1000000,
        items: [
          for (var i = 0; i < 12; i++)
            AllocationItem(
              id: 'demo-$i',
              group: ['Rutin', 'Pendidikan', 'Cadangan'][i ~/ 4],
              name: 'Pos ilustrasi ${i + 1}',
              amount: (i + 1) * 5000,
              note: i == 2
                  ? 'Catatan sintetis untuk melihat baris panjang pada ponsel.'
                  : '',
            ),
        ],
      ),
      1,
    );
    server['reserves'] = PlanSnapshot(
      MonthlyPlan(
        items: const [
          AllocationItem(
            id: 'reserve-demo',
            group: 'Sekali isi',
            name: 'Cadangan ilustratif',
            amount: 100000,
          ),
        ],
      ),
      1,
    );
  }
  bool offline = false;
  final server = <String, PlanSnapshot>{}, local = <String, PlanSnapshot>{};
  @override
  Future<PlanSnapshot?> cached(String period) async => local[period];
  @override
  Future<PlanSnapshot?> remote(String period) async {
    if (offline) throw StateError('Simulasi offline');
    return server[period];
  }

  @override
  Future<void> store(String period, PlanSnapshot value) async {
    local[period] = value;
  }

  @override
  Future<PlanSnapshot> save(String period, PlanSnapshot value) async {
    if (offline) throw StateError('Simulasi offline');
    if ((server[period]?.revision ?? 0) != value.revision) {
      throw StateError('Simulasi konflik');
    }
    final saved = PlanSnapshot(value.plan, value.revision + 1);
    server[period] = saved;
    local[period] = saved;
    return saved;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  Get.put<AuthController>(PreviewAuth());
  Get.put<SyncController>(PreviewSync());
  runApp(const Preview());
}

class Preview extends StatefulWidget {
  const Preview({super.key});
  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  final plans = PreviewPlans();
  bool dark = false, phone = false, rtl = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Wallet — pratinjau sintetis lokal',
    debugShowCheckedModeBanner: false,
    theme: dark
        ? AppTheme.dark(AppColors.defaultSeed)
        : AppTheme.light(AppColors.defaultSeed),
    home: Builder(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'SINTETIS · nominal ilustratif · simpan hanya RAM · tanpa akun/server',
                    ),
                    TextButton(
                      onPressed: () => setState(() => dark = !dark),
                      child: Text(dark ? 'Tema terang' : 'Tema gelap'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => phone = !phone),
                      child: Text(phone ? 'Lebar desktop' : 'Pratinjau 390 px'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => rtl = !rtl),
                      child: Text(rtl ? 'Arah LTR' : 'Arah RTL'),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => plans.offline = !plans.offline),
                      child: Text(
                        plans.offline
                            ? 'Simulasi: offline'
                            : 'Simulasikan offline',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = phone
                        ? math.min(390.0, constraints.maxWidth)
                        : constraints.maxWidth;
                    return Center(
                      child: SizedBox(
                        width: width,
                        child: MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(size: Size(width, constraints.maxHeight)),
                          child: Directionality(
                            textDirection: rtl
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            child: AdaptiveScaffold(
                              destinations: const [
                                AdaptiveDestination(
                                  icon: Icons.calendar_month_outlined,
                                  selectedIcon: Icons.calendar_month,
                                  label: 'Rencana Bulanan',
                                ),
                              ],
                              index: 0,
                              onSelect: (_) {},
                              body: MonthlyPlanEditor(service: plans),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

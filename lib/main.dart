import 'package:flutter/material.dart';
import 'package:financial_recording/app/bootstrap.dart';
import 'package:financial_recording/app/demo_mode.dart';
import 'package:financial_recording/app/money_manager_app.dart';
import 'package:financial_recording/data/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  await bootstrap();
  if (kDemoMode) await seedDemoData(DateTime.now());
  runApp(const MoneyManagerApp());
}

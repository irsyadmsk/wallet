import 'package:flutter/material.dart';
import 'package:financial_recording/app/bootstrap.dart';
import 'package:financial_recording/app/money_manager_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  runApp(const MoneyManagerApp());
}

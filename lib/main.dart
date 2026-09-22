import 'package:financial_recording/models/category_model/category_model.dart';
import 'package:financial_recording/models/transaction_model/transaction_model.dart';
import 'package:financial_recording/models/wallet_model/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Diointerceptors.init();
  await DBService.init();
  await Hive.initFlutter();

  // Load Theme Color
  String? savedColorStr = DBService.get("primary_color");
  if (savedColorStr != null) {
    try {
      primaryColor = Color(int.parse(savedColorStr));
    } catch (e) {
      debugPrint("Error parsing saved color: $e");
    }
  }

  Hive.registerAdapter(WalletModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  await Hive.openBox<WalletModel>('walletBox');
  await Hive.openBox<CategoryModel>('categories');
  await Hive.openBox<TransactionModel>('transactions');

  await _seedData();

  runMainApp();
}

Future<void> _seedData() async {
  var walletBox = Hive.box<WalletModel>('walletBox');
  var categoryBox = Hive.box<CategoryModel>('categories');

  if (walletBox.isEmpty) {
    // 1. Seed Wallet
    // User requested "Cash" with "logo Bi"
    var cashWallet = WalletModel(
      name: "Cash",
      balance: 0,
      iconPath: "assets/icon_pack/bank_logo/bi.png",
      gradient: [0xFF2196F3, 0xFF64B5F6], // Blue Gradient
    );
    await walletBox.add(cashWallet);

    // 2. Seed Categories
    if (categoryBox.isEmpty) {
      var categories = [
        CategoryModel(
          name: "Makan",
          iconPath: "assets/icon_pack/icons8-popcorn-100.png",
          type: "expense",
          color: "0xFFF44336", // Red
        ),
        CategoryModel(
          name: "Transport",
          iconPath: "assets/icon_pack/icons8-vehicle-96.png",
          type: "expense",
          color: "0xFFFF9800", // Orange
        ),
        CategoryModel(
          name: "Belanja",
          iconPath: "assets/icon_pack/icons8-ticket-96.png",
          type: "expense",
          color: "0xFFE91E63", // Pink
        ),
        CategoryModel(
          name: "Gaji",
          iconPath: "assets/icon_pack/icons8-gold-96.png",
          type: "income",
          color: "0xFF4CAF50", // Green
        ),
      ];

      for (var cat in categories) {
        await categoryBox.add(cat);
      }
    }
  }
}

runMainApp() async {
  return runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Financial Recording',
      navigatorKey: Get.key,
      locale: Locale('id', 'ID'),
      fallbackLocale: Locale('en', 'US'),
      debugShowCheckedModeBanner: false,
      theme: getDefaultTheme(),
      // home: LoginView(),
      home: DBService.get("token") == null ? MenuListView() : null,
      onGenerateRoute: (routeSettings) {
        return null;
      },
    );
  }
}

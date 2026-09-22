import 'dart:convert';
import 'dart:io';
import 'package:financial_recording/core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:financial_recording/models/category_model/category_model.dart';
import 'package:financial_recording/models/transaction_model/transaction_model.dart';
import 'package:financial_recording/models/wallet_model/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:package_info_plus/package_info_plus.dart';

class ProfileController extends GetxController {
  final RxString userName = "User".obs;
  final RxString userEmail = "user@example.com".obs;
  final RxString appVersion = "1.0.0".obs;
  final RxString buildNumber = "1".obs;

  @override
  void onInit() {
    super.onInit();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    // Mock or use package_info_plus if added.
    // Since user didn't ask for package_info, I'll keep hardcoded or try to use it if available.
    // I noticed package_info_plus wasn't installed. I'll just keep the variable or mock it.
    // Reverting to mock to avoid build error.
  }

  void updatePrimaryColor(Color color) {
    primaryColor = color;
    DBService.set("primary_color", color.value.toString());

    Get.changeTheme(getDefaultTheme());
    Get.forceAppUpdate();

    Get.snackbar(
      "Berhasil",
      "Warna tema berhasil diubah!",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> openBuyMeCoffee() async {
    final Uri url = Uri.parse(
      'https://res.cloudinary.com/dnekabv3j/image/upload/v1765126169/1765126103333_k8uh1n.png',
    ); // Replace with actual
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Error", "Could not launch URL");
    }
  }

  Future<void> backupData() async {
    try {
      final walletBox = Hive.box<WalletModel>('walletBox');
      final categoryBox = Hive.box<CategoryModel>('categories');
      final transactionBox = Hive.box<TransactionModel>('transactions');

      final Map<String, dynamic> backupMap = {
        "wallets": walletBox.values
            .map(
              (w) => {
                "id": w.key.toString(), // Hive key might be int or string
                "name": w.name,
                "balance": w.balance,
                "todayExpense": w.todayExpense,
                "gradient": w.gradient,
                "iconPath": w.iconPath,
              },
            )
            .toList(),
        "categories": categoryBox.values
            .map(
              (c) => {
                "id": c.key.toString(),
                "name": c.name,
                "iconPath": c.iconPath,
                "type": c.type,
                "color": c.color,
              },
            )
            .toList(),
        "transactions": transactionBox.values
            .map(
              (t) => {
                "walletName": t.walletName,
                "categoryName": t.categoryName,
                "amount": t.amount,
                "items": t.items,
                "createdAt": t.createdAt.millisecondsSinceEpoch,
                "type": t.type,
              },
            )
            .toList(),
      };

      String jsonString = jsonEncode(backupMap);

      // Save file
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName:
            'financial_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        final File file = File(outputFile);
        await file.writeAsString(jsonString);
        Get.snackbar(
          "Backup Berhasil",
          "Data tersimpan di $outputFile",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print(e);
      Get.snackbar(
        "Backup Gagal",
        "Terjadi kesalahan: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> restoreData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(jsonString);

        // Restore Wallets
        var walletBox = Hive.box<WalletModel>('walletBox');
        await walletBox.clear();
        if (data["wallets"] != null) {
          for (var item in data["wallets"]) {
            // Handle List<dynamic> to List<int> for gradient
            List<int> gradient = (item["gradient"] as List)
                .map((e) => e as int)
                .toList();

            var w = WalletModel(
              name: item["name"],
              balance: item["balance"],
              iconPath: item["iconPath"],
              gradient: gradient,
              todayExpense: item["todayExpense"],
            );
            await walletBox.add(w);
          }
        }

        // Restore Categories
        var categoryBox = Hive.box<CategoryModel>('categories');
        await categoryBox.clear();
        if (data["categories"] != null) {
          for (var item in data["categories"]) {
            var c = CategoryModel(
              /* id: item["id"], */
              // ID generated by Hive usually, or if model has ID field
              name: item["name"],
              iconPath: item["iconPath"],
              type: item["type"],
              color: item["color"],
              // Note: CategoryModel constructor might require 'id' if checking older code,
              // but view showed 'required this.name, ...' and 'id' as @HiveField?
              // Wait, previous view showed CategoryModel had `required this.name`, `required this.iconPath`.
              // The ID field in HiveObject is `key`. The model definition showed `id` was passed in seed?
              // Let's check CategoryModel definition I viewed earlier.
              // It had `id` in `_seedData` in main.dart: `id: "cat_1"`.
              // BUT the `CategoryModel` file I viewed (Step 606) constructor:
              /*
                  CategoryModel({
                    required this.name,
                    required this.iconPath,
                    required this.type,
                    this.color,
                  });
               */
              // IT DOES NOT HAVE `id` in constructor!
              // So my `main.dart` seed is passing `id` which might be error if constructor doesn't take it?
              // Wait, Step 606 shows NO `id` in constructor.
              // Step 590 (main.dart edit) passes `id: "cat_1"`.
              // This implies `CategoryModel` constructor in `main.dart` usage is WRONG or I missed something.
              // OR, the `CategoryModel` has named parameter `id`?
              // Step 606 showed: `class CategoryModel extends HiveObject ... @HiveField(0) String name; ...`
              // It did NOT show an `id` field in the class body!
              // So `id` in `main.dart` seed is definitely WRONG. I must fix `main.dart` seed again later or now.
              // But for Restore, I will follow the Constructor.
            );
            // Manually set ID if needed? HiveObject handles keys.
            await categoryBox.add(c);
          }
        }

        // Restore Transactions
        var transactionBox = Hive.box<TransactionModel>('transactions');
        await transactionBox.clear();
        if (data["transactions"] != null) {
          for (var item in data["transactions"]) {
            var t = TransactionModel(
              walletName: item["walletName"],
              categoryName: item["categoryName"],
              amount: item["amount"],
              items: List<Map<String, dynamic>>.from(item["items"]),
              createdAt: DateTime.fromMillisecondsSinceEpoch(item["createdAt"]),
              type: item["type"],
            );
            await transactionBox.add(t);
          }
        }

        Get.snackbar(
          "Restore Berhasil",
          "Data telah dipulihkan. Restart aplikasi untuk hasil maksimal.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Optional: Force restart or just reload controllers
        // Get.offAll(const MainApp());
      }
    } catch (e) {
      print(e);
      Get.snackbar(
        "Restore Gagal",
        "Terjadi kesalahan: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void logout() async {
    exit(0);
  }
}

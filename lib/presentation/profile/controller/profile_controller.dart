import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/core.dart';
import 'package:financial_recording/models/category_model/category_model.dart';
import 'package:financial_recording/models/transaction_model/transaction_model.dart';
import 'package:financial_recording/models/wallet_model/wallet_model.dart';
import 'package:financial_recording/util/budget_service/budget_service.dart';

class ProfileController extends GetxController {
  final RxString userName = AppConfig.appAuthor.obs;
  final RxString userEmail = AppConfig.appAuthorEmail.obs;
  final RxString appVersion = AppConfig.appVersion.obs;
  final RxInt monthlyBudget = BudgetService.getBudgetLimit().obs;

  @override
  void onInit() {
    super.onInit();
    monthlyBudget.value = BudgetService.getBudgetLimit();
  }

  void updatePrimaryColor(Color color) {
    primaryColor = color;
    DBService.set("primary_color", color.value.toString());

    Get.changeTheme(getDefaultTheme());
    Get.forceAppUpdate();

    Get.snackbar(
      "Berhasil",
      "Warna tema berhasil diubah!",
      backgroundColor: primaryColor,
      colorText: Colors.white,
    );
  }

  Future<void> setBudget(int newLimit) async {
    await BudgetService.setBudgetLimit(newLimit);
    monthlyBudget.value = newLimit;
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().initializeData();
    }
    Get.snackbar(
      "Sukses",
      "Target anggaran bulanan berhasil diperbarui",
      backgroundColor: const Color(0xFF10B981),
      colorText: Colors.white,
    );
  }

  Future<void> exportToCsv() async {
    try {
      final transactionBox = Hive.box<TransactionModel>(AppConfig.transactionBoxName);
      final transactions = transactionBox.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (transactions.isEmpty) {
        Get.snackbar("Informasi", "Belum ada data transaksi untuk diekspor");
        return;
      }

      final StringBuffer csv = StringBuffer();
      // CSV Header
      csv.writeln("Tanggal,Waktu,Jenis,Kategori,Wallet,Nominal,Rincian Item");

      for (var t in transactions) {
        final date =
            "${t.createdAt.year}-${t.createdAt.month.toString().padLeft(2, '0')}-${t.createdAt.day.toString().padLeft(2, '0')}";
        final time =
            "${t.createdAt.hour.toString().padLeft(2, '0')}:${t.createdAt.minute.toString().padLeft(2, '0')}";
        final type = t.type == 'income'
            ? 'Pemasukan'
            : t.type == 'expense'
                ? 'Pengeluaran'
                : 'Transfer';
        final itemsSummary = t.items
            .map((item) => "${item['name'] ?? ''}: Rp ${item['nominal'] ?? ''}")
            .join('; ')
            .replaceAll('"', '""');

        csv.writeln(
          '"$date","$time","$type","${t.categoryName}","${t.walletName}",${t.amount},"$itemsSummary"',
        );
      }

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Laporan CSV',
        fileName: 'laporan_keuangan_${DateTime.now().millisecondsSinceEpoch}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile != null) {
        final File file = File(outputFile);
        await file.writeAsString(csv.toString());
        Get.snackbar(
          "Ekspor Berhasil",
          "File CSV berhasil disimpan di $outputFile",
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Ekspor Gagal",
        "Terjadi kesalahan: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> backupData() async {
    try {
      final walletBox = Hive.box<WalletModel>(AppConfig.walletBoxName);
      final categoryBox = Hive.box<CategoryModel>(AppConfig.categoryBoxName);
      final transactionBox = Hive.box<TransactionModel>(AppConfig.transactionBoxName);

      final Map<String, dynamic> backupMap = {
        "author": AppConfig.appAuthor,
        "exportedAt": DateTime.now().toIso8601String(),
        "wallets": walletBox.values.map((w) => w.toJson()).toList(),
        "categories": categoryBox.values.map((c) => c.toJson()).toList(),
        "transactions": transactionBox.values.map((t) => t.toJson()).toList(),
      };

      String jsonString = jsonEncode(backupMap);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Backup Data JSON',
        fileName: 'backup_moneymanager_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        final File file = File(outputFile);
        await file.writeAsString(jsonString);
        Get.snackbar(
          "Backup Berhasil",
          "Data tersimpan di $outputFile",
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
      }
    } catch (e) {
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
        var walletBox = Hive.box<WalletModel>(AppConfig.walletBoxName);
        await walletBox.clear();
        if (data["wallets"] != null) {
          for (var item in data["wallets"]) {
            await walletBox.add(WalletModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }

        // Restore Categories
        var categoryBox = Hive.box<CategoryModel>(AppConfig.categoryBoxName);
        await categoryBox.clear();
        if (data["categories"] != null) {
          for (var item in data["categories"]) {
            await categoryBox.add(CategoryModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }

        // Restore Transactions
        var transactionBox = Hive.box<TransactionModel>(AppConfig.transactionBoxName);
        await transactionBox.clear();
        if (data["transactions"] != null) {
          for (var item in data["transactions"]) {
            await transactionBox.add(TransactionModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }

        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().initializeData();
        }
        if (Get.isRegistered<WalletController>()) {
          Get.find<WalletController>().refresh();
        }

        Get.snackbar(
          "Restore Berhasil",
          "Data telah berhasil dipulihkan dari cadangan.",
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Restore Gagal",
        "Terjadi kesalahan saat memulihkan: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

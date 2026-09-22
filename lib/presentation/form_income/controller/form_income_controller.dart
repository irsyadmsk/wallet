import 'package:financial_recording/models/category_model/category_model.dart';
import 'package:financial_recording/models/transaction_model/transaction_model.dart';
import 'package:financial_recording/presentation/dashboard/controller/dashboard_controller.dart';
import 'package:financial_recording/presentation/wallet/controller/wallet_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:financial_recording/models/wallet_model/wallet_model.dart';
import 'package:intl/intl.dart';

class FormIncomeController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = "".obs;
  final RxInt counter = 1.obs;
  var box = Hive.box<WalletModel>('walletBox');
  var boxCategories = Hive.box<CategoryModel>('categories');
  var boxTransactions = Hive.box<TransactionModel>('transactions');
  RxList<Map<String, String>> incomeList = <Map<String, String>>[].obs;
  final RxList<Map<String, dynamic>> wallets = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, String>> categories = <Map<String, String>>[].obs;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxString selectedWalletKey = "".obs;
  final RxString selectedCategoryKey = "".obs;

  @override
  void onInit() {
    super.onInit();
    addItem();
    initializeData();
  }

  Future<void> initializeData() async {
    // Clear existing data to avoid duplicates if called multiple times
    wallets.clear();
    categories.clear();

    for (var i = 0; i < box.length; i++) {
      final key = box.keyAt(i);
      final WalletModel wallet = box.get(key)!;
      wallets.add({
        "label":
            "${wallet.name} - ${"Rp. ${NumberFormat.decimalPattern('id').format(wallet.balance)}"}",
        "value": key.toString(),
        // "disabled": wallet.balance == 0,
      });
    }

    wallets.sort((a, b) {
      double balanceA = double.parse(
        a['label'].split('Rp. ')[1].replaceAll(',', ''),
      );
      double balanceB = double.parse(
        b['label'].split('Rp. ')[1].replaceAll(',', ''),
      );
      return balanceB.compareTo(balanceA);
    });

    for (var i = 0; i < boxCategories.length; i++) {
      final key = boxCategories.keyAt(i);
      final CategoryModel category = boxCategories.get(key)!;
      if (category.type == "expense") {
        continue;
      }
      categories.add({"label": category.name, "value": key.toString()});
    }
  }

  void addItem() {
    incomeList.add({"name": "", "nominal": ""});
  }

  void removeItem(Map<String, String> item) {
    incomeList.remove(item);
  }

  // Calculate total income by summing all nominal values
  int get totalIncome {
    return incomeList.fold<int>(0, (sum, item) {
      final nominalStr = item["nominal"] ?? "";
      // Remove thousand separators (dots) and parse
      final cleanedStr = nominalStr.replaceAll(".", "");
      final nominal = int.tryParse(cleanedStr) ?? 0;
      return sum + nominal;
    });
  }

  Future<void> saveIncome() async {
    if (selectedWalletKey.value.isEmpty) {
      Get.snackbar("Error", "Pilih Wallet terlebih dahulu");
      return;
    }
    if (selectedCategoryKey.value.isEmpty) {
      Get.snackbar("Error", "Pilih Kategori terlebih dahulu");
      return;
    }

    isLoading.value = true;
    try {
      final walletKey = int.parse(selectedWalletKey.value);
      final categoryKey = int.parse(selectedCategoryKey.value);

      final WalletModel wallet = box.get(walletKey)!;
      final CategoryModel category = boxCategories.get(categoryKey)!;

      // Create transaction items
      List<Map<String, dynamic>> items = incomeList.map((e) {
        final nominalStr = e["nominal"] ?? "0";
        final cleanedStr = nominalStr.replaceAll(".", "");
        return {"name": e["name"], "nominal": int.tryParse(cleanedStr) ?? 0};
      }).toList();

      final transaction = TransactionModel(
        walletName: wallet.name,
        categoryName: category.name,
        amount: totalIncome,
        items: items,
        createdAt: DateTime.now(),
        type: 'income',
      );

      // Save transaction
      final transactionBox = Hive.box<TransactionModel>('transactions');
      await transactionBox.add(transaction);

      // Update wallet balance (increase for income)
      wallet.balance += totalIncome;
      await box.put(walletKey, wallet);
      final controller = Get.find<WalletController>();
      final controllerDashboard = Get.find<DashboardController>();

      controllerDashboard.initializeData();
      controller.refresh();
      Get.back();
      Get.snackbar("Sukses", "Pemasukan berhasil disimpan");
    } catch (e) {
      print(e);
      Get.snackbar("Error", "Gagal menyimpan pemasukan: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

import 'package:financial_recording/core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class WalletDetailController extends GetxController {
  final WalletModel wallet;
  WalletDetailController(this.wallet);

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  // Use filteredTransactions for UI
  final RxList<TransactionModel> filteredTransactions =
      <TransactionModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = "".obs;

  // Stats
  final RxInt monthlyIncome = 0.obs;
  final RxInt monthlyExpense = 0.obs;

  // Filter States
  final Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(null);
  final RxString selectedCategory = "".obs;
  final RxString selectedType = "Semua".obs; // Semua, Income, Expense, Transfer

  // Options
  final RxList<String> categoryOptions = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  Future<void> initializeData() async {
    isLoading.value = true;
    try {
      if (!Hive.isBoxOpen('transactions')) {
        await Hive.openBox<TransactionModel>('transactions');
      }
      var box = Hive.box<TransactionModel>('transactions');

      var allTransactions = box.values.toList();
      var walletTransactions = allTransactions
          .where((t) => t.walletName == wallet.name)
          .toList();

      walletTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      transactions.assignAll(walletTransactions);

      final categories = <String>{};
      for (var t in walletTransactions) {
        categories.add(t.categoryName);
      }
      categoryOptions.assignAll(categories.toList());

      final now = DateTime.now();
      selectedDateRange.value = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      );

      applyFilters();

      isLoading.value = false;
      hasError.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = e.toString();
    }
  }

  void applyFilters() {
    List<TransactionModel> temp = List.from(transactions);

    if (selectedDateRange.value != null) {
      temp = temp.where((t) {
        return t.createdAt.isAfter(
              selectedDateRange.value!.start.subtract(const Duration(days: 1)),
            ) &&
            t.createdAt.isBefore(
              selectedDateRange.value!.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    if (selectedCategory.value.isNotEmpty) {
      temp = temp
          .where((t) => t.categoryName == selectedCategory.value)
          .toList();
    }

    if (selectedType.value != "Semua") {
      String typeKey = "";
      if (selectedType.value == "Pemasukan") typeKey = "income";
      if (selectedType.value == "Pengeluaran") typeKey = "expense";
      if (selectedType.value == "Transfer") typeKey = "transfer";

      if (typeKey.isNotEmpty) {
        temp = temp.where((t) => t.type == typeKey).toList();
      }
    }

    filteredTransactions.assignAll(temp);
    calculateTotals();
  }

  void calculateTotals() {
    int income = 0;
    int expense = 0;
    for (var item in filteredTransactions) {
      if (item.type == 'income') {
        income += item.amount;
      } else if (item.type == 'expense') {
        expense += item.amount;
      }
    }
    monthlyIncome.value = income;
    monthlyExpense.value = expense;
  }

  void resetFilters() {
    final now = DateTime.now();
    selectedDateRange.value = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    selectedCategory.value = "";
    selectedType.value = "Semua";
    applyFilters();
  }

  void deleteWallet() {
    Get.defaultDialog(
      title: "Hapus Wallet",
      middleText: "Apakah anda yakin ingin menghapus wallet ini?",
      textConfirm: "Ya, Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        await wallet.delete();
        final walletController = Get.find<WalletController>();
        walletController.initializeData(); // Refresh list
        Get.back(); // Close dialog
        Get.back(); // Go back to wallet list
        Get.snackbar("Sukses", "Wallet berhasil dihapus");
      },
    );
  }
}

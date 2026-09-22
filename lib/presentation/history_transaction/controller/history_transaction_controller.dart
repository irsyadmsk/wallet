import 'package:financial_recording/models/transaction_model/transaction_model.dart';
import 'package:financial_recording/models/wallet_model/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class HistoryTransactionController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = "".obs;
  final RxInt counter = 0.obs;
  // final RxList<Map<String, dynamic>> histories = <Map<String, dynamic>>[].obs;
  var box = Hive.box<TransactionModel>('transactions');
  final RxList<TransactionModel> histories = <TransactionModel>[].obs;
  final RxList<TransactionModel> filteredHistories = <TransactionModel>[].obs;

  // Filter States
  final Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(null);
  final RxString selectedWallet = "".obs; // Store wallet name
  final RxString selectedCategory = "".obs;
  final RxString selectedType = "Semua".obs; // Semua, Income, Expense, Transfer
  final RxString searchQuery = "".obs;

  // Options for Dropdowns
  final RxList<String> walletOptions = <String>[].obs;
  final RxList<String> categoryOptions = <String>[].obs;

  final RxInt totalIncome = 0.obs;
  final RxInt totalExpense = 0.obs;

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  Future<void> initializeData() async {
    isLoading.value = true;
    try {
      histories.clear();
      // Load all transactions
      final allTransactions = box.values.toList();
      // Sort by date desc
      allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      histories.assignAll(allTransactions);

      // Load Filter Options from actual data
      final wallets = <String>{};
      final categories = <String>{};

      for (var t in allTransactions) {
        if (t.type == 'transfer') {
          // For transfer, walletName is "Source -> Dest", maybe complicated to filter strictly
          // We can skip or parse. For simplicity, we add if distinct
        } else {
          wallets.add(t.walletName);
        }
        categories.add(t.categoryName);
      }

      // Also load all wallets from WalletBox for complete list
      final walletBox = Hive.box<WalletModel>('walletBox');
      for (var w in walletBox.values) {
        wallets.add(w.name);
      }

      walletOptions.assignAll(wallets.toList());
      categoryOptions.assignAll(categories.toList());

      // Default to current month
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
    List<TransactionModel> temp = List.from(histories);

    // 0. Search Query
    if (searchQuery.value.trim().isNotEmpty) {
      final query = searchQuery.value.trim().toLowerCase();
      temp = temp.where((t) {
        final inCategory = t.categoryName.toLowerCase().contains(query);
        final inWallet = t.walletName.toLowerCase().contains(query);
        final inItems = t.items.any((item) =>
            (item['name'] ?? '').toString().toLowerCase().contains(query));
        return inCategory || inWallet || inItems;
      }).toList();
    }

    // 1. Date Range
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

    // 2. Wallet
    if (selectedWallet.value.isNotEmpty) {
      temp = temp.where((t) {
        if (t.type == 'transfer') {
          return t.walletName.contains(selectedWallet.value);
        }
        return t.walletName == selectedWallet.value;
      }).toList();
    }

    // 3. Category
    if (selectedCategory.value.isNotEmpty) {
      temp = temp
          .where((t) => t.categoryName == selectedCategory.value)
          .toList();
    }

    // 4. Type
    if (selectedType.value != "Semua") {
      String typeKey = "";
      if (selectedType.value == "Pemasukan") typeKey = "income";
      if (selectedType.value == "Pengeluaran") typeKey = "expense";
      if (selectedType.value == "Transfer") typeKey = "transfer";

      if (typeKey.isNotEmpty) {
        temp = temp.where((t) => t.type == typeKey).toList();
      }
    }

    filteredHistories.assignAll(temp);
    calculateTotals();
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    try {
      final walletBox = Hive.box<WalletModel>('walletBox');

      if (transaction.type == 'expense') {
        // Refund expense back to wallet
        for (var key in walletBox.keys) {
          final w = walletBox.get(key);
          if (w != null && w.name == transaction.walletName) {
            w.balance += transaction.amount;
            await walletBox.put(key, w);
            break;
          }
        }
      } else if (transaction.type == 'income') {
        // Deduct income from wallet
        for (var key in walletBox.keys) {
          final w = walletBox.get(key);
          if (w != null && w.name == transaction.walletName) {
            w.balance -= transaction.amount;
            await walletBox.put(key, w);
            break;
          }
        }
      } else if (transaction.type == 'transfer') {
        // Transfer was "Source -> Dest", reverse it
        final parts = transaction.walletName.split(" -> ");
        if (parts.length == 2) {
          final sourceName = parts[0].trim();
          final destName = parts[1].trim();

          for (var key in walletBox.keys) {
            final w = walletBox.get(key);
            if (w != null && w.name == sourceName) {
              w.balance += transaction.amount;
              await walletBox.put(key, w);
            } else if (w != null && w.name == destName) {
              w.balance -= transaction.amount;
              await walletBox.put(key, w);
            }
          }
        }
      }

      await transaction.delete();
      await initializeData();

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().initializeData();
      }
      if (Get.isRegistered<WalletController>()) {
        Get.find<WalletController>().refresh();
      }

      Get.back();
      Get.snackbar("Sukses", "Transaksi berhasil dihapus");
    } catch (e) {
      Get.snackbar("Error", "Gagal menghapus transaksi: $e");
    }
  }

  void calculateTotals() {
    int income = 0;
    int expense = 0;
    for (var item in filteredHistories) {
      if (item.type == 'income') {
        income += item.amount;
      } else if (item.type == 'expense') {
        expense += item.amount;
      }
    }
    totalIncome.value = income;
    totalExpense.value = expense;
  }

  void resetFilters() {
    final now = DateTime.now();
    selectedDateRange.value = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    selectedWallet.value = "";
    selectedCategory.value = "";
    selectedType.value = "Semua";
    applyFilters();
  }

  void increment() {
    counter.value++;
  }

  void decrement() {
    counter.value--;
  }
}

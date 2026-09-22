import 'package:financial_recording/models/transaction_model/transaction_model.dart';
import 'package:financial_recording/models/wallet_model/wallet_model.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../core.dart';

class DashboardController extends GetxController {
  var box = Hive.box<WalletModel>('walletBox');
  var boxCategories = Hive.box<CategoryModel>('categories');
  var boxTransactions = Hive.box<TransactionModel>('transactions');
  final RxInt balance = 0.obs;
  final RxInt todayExpense = 0.obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxBool isObscured = false.obs;

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  Future<void> initializeData() async {
    try {
      // Simulate API call
      balance.value = 0;
      todayExpense.value = 0;
      for (var item in box.values) {
        balance.value += item.balance;
      }
      final now = DateTime.now();
      transactions.clear();
      transactions.addAll(boxTransactions.values.toList());
      // sort by date desc
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      for (var item in boxTransactions.values) {
        final created = item.createdAt;

        final isToday =
            created.year == now.year &&
            created.month == now.month &&
            created.day == now.day;

        if (isToday && item.type == "expense") {
          todayExpense.value += item.amount;
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load data");
    }
  }
}

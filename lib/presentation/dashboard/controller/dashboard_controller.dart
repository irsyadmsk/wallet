import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/models/transaction_model/transaction_model.dart';
import 'package:financial_recording/models/wallet_model/wallet_model.dart';
import 'package:financial_recording/util/budget_service/budget_service.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class DashboardController extends GetxController {
  final RxInt balance = 0.obs;
  final RxInt todayExpense = 0.obs;
  final RxInt thisMonthIncome = 0.obs;
  final RxInt thisMonthExpense = 0.obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxBool isObscured = false.obs;
  final Rx<BudgetInfo?> budgetInfo = Rx<BudgetInfo?>(null);

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return "Selamat Pagi";
    if (hour >= 11 && hour < 15) return "Selamat Siang";
    if (hour >= 15 && hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  String get authorName => AppConfig.appAuthor;

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  Future<void> initializeData() async {
    try {
      final box = Hive.box<WalletModel>(AppConfig.walletBoxName);
      final boxTransactions = Hive.box<TransactionModel>(AppConfig.transactionBoxName);

      // 1. Calculate balance
      int totalBalance = 0;
      for (var item in box.values) {
        totalBalance += item.balance;
      }
      balance.value = totalBalance;

      // 2. Process transactions
      final now = DateTime.now();
      int todayExp = 0;
      int mIncome = 0;
      int mExpense = 0;

      final allTransactions = boxTransactions.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      transactions.assignAll(allTransactions);

      for (var item in allTransactions) {
        final created = item.createdAt;
        final isToday =
            created.year == now.year &&
            created.month == now.month &&
            created.day == now.day;
        final isThisMonth =
            created.year == now.year && created.month == now.month;

        if (isToday && item.type == "expense") {
          todayExp += item.amount;
        }

        if (isThisMonth) {
          if (item.type == "income") {
            mIncome += item.amount;
          } else if (item.type == "expense") {
            mExpense += item.amount;
          }
        }
      }

      todayExpense.value = todayExp;
      thisMonthIncome.value = mIncome;
      thisMonthExpense.value = mExpense;

      // 3. Calculate budget info
      budgetInfo.value = BudgetService.calculateCurrentMonthBudget();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data dashboard: $e");
    }
  }
}

import 'package:get/get.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

class BalancePoint {
  final DateTime month;
  final int balance;
  BalancePoint(this.month, this.balance);
}

class AccountDetailController extends GetxController {
  AccountDetailController(this.accountId);

  final String accountId;
  final _accounts = AccountRepository();
  final _txs = TxRepository();

  final Rx<AccountModel?> account = Rx<AccountModel?>(null);
  final RxList<TxModel> transactions = <TxModel>[].obs;
  final RxList<BalancePoint> balanceHistory = <BalancePoint>[].obs;
  final RxInt monthIncome = 0.obs;
  final RxInt monthExpense = 0.obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  Future<void> saveAccount(AccountModel updated) async {
    await _accounts.upsert(updated);
    refresh();
  }

  @override
  void refresh() {
    account.value = _accounts.byId(accountId);
    final list = _txs.forAccount(accountId)..sort((a, b) => b.date.compareTo(a.date));
    transactions.assignAll(list);

    final now = DateTime.now();
    final monthList = list.where((t) => t.date.year == now.year && t.date.month == now.month);
    monthIncome.value = monthList
        .where((t) => t.type == TxType.income || (t.type == TxType.transfer && t.toAccountId == accountId))
        .fold(0, (s, t) => s + t.amount);
    monthExpense.value = monthList
        .where((t) => t.type == TxType.expense || (t.type == TxType.transfer && t.accountId == accountId))
        .fold(0, (s, t) => s + t.amount);

    _refreshBalanceHistory(list, now);
  }

  /// Month-end balance for the last 6 months, replayed from this account's
  /// own ledger entries (both legs of a transfer count).
  void _refreshBalanceHistory(List<TxModel> accountTxs, DateTime now) {
    final acc = account.value;
    if (acc == null) {
      balanceHistory.clear();
      return;
    }
    final sorted = accountTxs.toList()..sort((a, b) => a.date.compareTo(b.date));
    var running = acc.openingBalance;
    var txIndex = 0;
    const monthsBack = 6;
    final points = <BalancePoint>[];
    for (var i = monthsBack - 1; i >= 0; i--) {
      final cutoff = DateTime(now.year, now.month - i + 1, 1);
      while (txIndex < sorted.length && sorted[txIndex].date.isBefore(cutoff)) {
        final t = sorted[txIndex];
        if (t.accountId == accountId) {
          running += t.signedAmountOnPrimaryAccount;
        } else if (t.isTransfer && t.toAccountId == accountId) {
          running += t.amount;
        }
        txIndex++;
      }
      points.add(BalancePoint(DateTime(now.year, now.month - i, 1), running));
    }
    balanceHistory.assignAll(points);
  }
}

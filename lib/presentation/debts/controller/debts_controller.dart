import 'package:get/get.dart';
import 'package:financial_recording/data/models/debt_model/debt_model.dart';
import 'package:financial_recording/data/repositories/debt_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/services/ledger_service.dart';

enum DebtFilter {
  all('Semua'),
  active('Belum Lunas'),
  debts('Utang Saya'),
  loans('Piutang Saya');

  final String label;
  const DebtFilter(this.label);
}

class DebtsController extends GetxController {
  DebtsController({
    DebtRepository? debtRepository,
    TxCategoryRepository? categoryRepository,
    LedgerService? ledgerService,
  })  : _repo = debtRepository ?? DebtRepository(),
        _categories = categoryRepository ?? TxCategoryRepository(),
        _ledger = ledgerService ?? LedgerService();

  final DebtRepository _repo;
  final TxCategoryRepository _categories;
  final LedgerService _ledger;

  final RxList<DebtLoanModel> allItems = <DebtLoanModel>[].obs;
  final Rx<DebtFilter> filter = DebtFilter.all.obs;
  final RxInt totalDebt = 0.obs;
  final RxInt totalLoan = 0.obs;

  int get netBalance => totalLoan.value - totalDebt.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void load() {
    final list = _repo.all();
    allItems.assignAll(list);

    int dSum = 0;
    int lSum = 0;
    for (final item in list) {
      if (!item.isSettled) {
        if (item.isLoan) {
          lSum += item.remainingAmount;
        } else {
          dSum += item.remainingAmount;
        }
      }
    }
    totalDebt.value = dSum;
    totalLoan.value = lSum;
  }

  List<DebtLoanModel> get filteredList {
    switch (filter.value) {
      case DebtFilter.all:
        return allItems;
      case DebtFilter.active:
        return allItems.where((d) => !d.isSettled).toList();
      case DebtFilter.debts:
        return allItems.where((d) => !d.isLoan).toList();
      case DebtFilter.loans:
        return allItems.where((d) => d.isLoan).toList();
    }
  }

  Future<void> saveDebt(
    DebtLoanModel model, {
    String? accountId,
    bool syncWallet = false,
  }) async {
    await _repo.upsert(model);

    // If syncing wallet on creation:
    // Utang baru (borrow money) -> Kas bertambah (income)
    // Piutang baru (lend money to someone) -> Kas berkurang (expense)
    if (syncWallet && accountId != null && accountId.isNotEmpty) {
      final now = DateTime.now();
      if (model.isLoan) {
        // We gave money out -> expense
        final cats = _categories.byType(1);
        final catId = cats.isNotEmpty ? cats.first.id : 'expense_other';
        await _ledger.addExpense(
          accountId: accountId,
          categoryId: catId,
          amount: model.totalAmount,
          date: now,
          memo: 'Pinjaman ke ${model.personName}${model.notes != null ? ' (${model.notes})' : ''}',
        );
      } else {
        // We received loan money -> income
        final cats = _categories.byType(0);
        final catId = cats.isNotEmpty ? cats.first.id : 'income_other';
        await _ledger.addIncome(
          accountId: accountId,
          categoryId: catId,
          amount: model.totalAmount,
          date: now,
          memo: 'Terima pinjaman dari ${model.personName}${model.notes != null ? ' (${model.notes})' : ''}',
        );
      }
    }

    load();
  }

  Future<void> recordPayment(
    String debtId,
    int amount, {
    String? accountId,
    bool syncWallet = false,
    String? notes,
  }) async {
    final debt = _repo.byId(debtId);
    if (debt == null || amount <= 0) return;

    await _repo.recordPayment(debtId, amount);

    // If syncing wallet on payment:
    // Paying debt (bayar utang) -> uang keluar (expense)
    // Receiving loan payment (terima cicilan piutang) -> uang masuk (income)
    if (syncWallet && accountId != null && accountId.isNotEmpty) {
      final now = DateTime.now();
      if (debt.isLoan) {
        // Person paid us -> income
        final cats = _categories.byType(0);
        final catId = cats.isNotEmpty ? cats.first.id : 'income_other';
        await _ledger.addIncome(
          accountId: accountId,
          categoryId: catId,
          amount: amount,
          date: now,
          memo: 'Cicilan Piutang dari ${debt.personName}${notes != null ? ' ($notes)' : ''}',
        );
      } else {
        // We paid person -> expense
        final cats = _categories.byType(1);
        final catId = cats.isNotEmpty ? cats.first.id : 'expense_other';
        await _ledger.addExpense(
          accountId: accountId,
          categoryId: catId,
          amount: amount,
          date: now,
          memo: 'Bayar Cicilan Utang ke ${debt.personName}${notes != null ? ' ($notes)' : ''}',
        );
      }
    }

    load();
  }

  Future<void> deleteDebt(String id) async {
    await _repo.delete(id);
    load();
  }
}

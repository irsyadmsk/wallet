import 'package:financial_recording/models/transaction_model/transaction_model.dart';

abstract class ITransactionRepository {
  Future<List<TransactionModel>> getAllTransactions();
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(TransactionModel transaction);
  Future<int> getTotalExpense({DateTime? start, DateTime? end});
  Future<int> getTotalIncome({DateTime? start, DateTime? end});
}

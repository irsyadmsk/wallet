import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/models/transaction_model/transaction_model.dart';
import 'package:financial_recording/models/wallet_model/wallet_model.dart';

void main() {
  group('Money Manager Logic Tests', () {
    test('TransactionModel stores attributes correctly', () {
      final tx = TransactionModel(
        walletName: 'BCA',
        categoryName: 'Makan',
        amount: 50000,
        items: [
          {'name': 'Ayam Bakar', 'nominal': 30000},
          {'name': 'Es Teh', 'nominal': 20000},
        ],
        createdAt: DateTime(2026, 9, 22, 12, 0),
        type: 'expense',
      );

      expect(tx.walletName, 'BCA');
      expect(tx.categoryName, 'Makan');
      expect(tx.amount, 50000);
      expect(tx.items.length, 2);
      expect(tx.type, 'expense');
    });

    test('WalletModel handles balance calculations correctly', () {
      final wallet = WalletModel(
        name: 'Dompet Utama',
        iconPath: 'assets/icon_pack/bank_logo/bca.png',
        balance: 250000,
        gradient: [0xFF2196F3, 0xFF64B5F6],
      );

      expect(wallet.balance, 250000);
      expect(wallet.gradientColors.length, 2);

      // Simulate expense deduction
      const expenseAmount = 75000;
      wallet.balance -= expenseAmount;
      expect(wallet.balance, 175000);

      // Simulate income addition
      const incomeAmount = 500000;
      wallet.balance += incomeAmount;
      expect(wallet.balance, 675000);
    });

    test('Category percentage calculation is accurate', () {
      final expenses = [
        {'category': 'Makan', 'amount': 60000},
        {'category': 'Transport', 'amount': 40000},
      ];

      final totalExpense = expenses.fold<int>(0, (sum, e) => sum + (e['amount'] as int));
      expect(totalExpense, 100000);

      final makanPct = ((expenses[0]['amount'] as int) / totalExpense) * 100;
      final transportPct = ((expenses[1]['amount'] as int) / totalExpense) * 100;

      expect(makanPct, 60.0);
      expect(transportPct, 40.0);
    });
  });
}

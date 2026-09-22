import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/models/category_model/category_model.dart';
import 'package:financial_recording/models/transaction_model/transaction_model.dart';
import 'package:financial_recording/models/wallet_model/wallet_model.dart';

void main() {
  group('Money Manager Logic & Serialization Tests', () {
    test('TransactionModel stores attributes and converts to/from JSON correctly', () {
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

      // Test JSON Serialization
      final json = tx.toJson();
      expect(json['walletName'], 'BCA');
      expect(json['amount'], 50000);

      // Test JSON Deserialization
      final fromJsonTx = TransactionModel.fromJson(json);
      expect(fromJsonTx.walletName, tx.walletName);
      expect(fromJsonTx.categoryName, tx.categoryName);
      expect(fromJsonTx.amount, tx.amount);
      expect(fromJsonTx.type, tx.type);
    });

    test('WalletModel handles JSON serialization and balance correctly', () {
      final wallet = WalletModel(
        name: 'Dompet Utama',
        iconPath: 'assets/icon_pack/bank_logo/bca.png',
        balance: 250000,
        gradient: [0xFF4F46E5, 0xFF6366F1],
      );

      expect(wallet.balance, 250000);
      expect(wallet.gradientColors.length, 2);

      // Test JSON
      final json = wallet.toJson();
      expect(json['name'], 'Dompet Utama');
      expect(json['balance'], 250000);

      final restoredWallet = WalletModel.fromJson(json);
      expect(restoredWallet.name, 'Dompet Utama');
      expect(restoredWallet.balance, 250000);
    });

    test('CategoryModel handles JSON serialization correctly', () {
      final category = CategoryModel(
        name: 'Gaji',
        iconPath: 'assets/icon_pack/icons8-gold-96.png',
        type: 'income',
        color: '0xFF10B981',
      );

      final json = category.toJson();
      expect(json['name'], 'Gaji');
      expect(json['type'], 'income');

      final restoredCategory = CategoryModel.fromJson(json);
      expect(restoredCategory.name, 'Gaji');
      expect(restoredCategory.type, 'income');
      expect(restoredCategory.color, '0xFF10B981');
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

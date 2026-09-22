import 'package:financial_recording/models/wallet_model/wallet_model.dart';

abstract class IWalletRepository {
  Future<List<WalletModel>> getWallets();
  Future<int> getTotalBalance();
  Future<void> addWallet(WalletModel wallet);
  Future<void> updateWallet(dynamic key, WalletModel wallet);
  Future<void> deleteWallet(dynamic key);
}

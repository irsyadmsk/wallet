import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/models/wallet_model/wallet_model.dart';
import 'i_wallet_repository.dart';

class WalletRepository implements IWalletRepository {
  Box<WalletModel> get _box => Hive.box<WalletModel>(AppConfig.walletBoxName);

  @override
  Future<List<WalletModel>> getWallets() async {
    return _box.values.toList();
  }

  @override
  Future<int> getTotalBalance() async {
    int total = 0;
    for (var w in _box.values) {
      total += w.balance;
    }
    return total;
  }

  @override
  Future<void> addWallet(WalletModel wallet) async {
    await _box.add(wallet);
  }

  @override
  Future<void> updateWallet(dynamic key, WalletModel wallet) async {
    await _box.put(key, wallet);
  }

  @override
  Future<void> deleteWallet(dynamic key) async {
    await _box.delete(key);
  }
}

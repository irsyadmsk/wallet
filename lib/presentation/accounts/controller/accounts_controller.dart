import 'package:get/get.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';

class AccountsController extends GetxController {
  final _accounts = AccountRepository();
  final _ledger = LedgerService();

  final RxMap<AccountGroupType, List<AccountModel>> grouped = <AccountGroupType, List<AccountModel>>{}.obs;
  final RxInt netWorth = 0.obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  void refresh() {
    grouped.assignAll(_accounts.grouped());
    netWorth.value = _accounts.netWorth;
  }

  Future<void> saveAccount(AccountModel account) async {
    await _accounts.upsert(account);
    refresh();
  }

  Future<void> deleteAccount(String id) async {
    await _accounts.delete(id);
    refresh();
  }

  Future<void> recomputeBalances() async {
    await _ledger.recomputeAllBalances();
    refresh();
  }
}

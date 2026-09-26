import 'package:get/get.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/data/repositories/account_group_repository.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';

class AccountsController extends GetxController {
  final _accounts = AccountRepository();
  final _ledger = LedgerService();

  final _groups = AccountGroupRepository();
  static final _other = AccountGroupType.other.code;

  /// Non-empty groups in display order, each with its accounts.
  final RxList<(AccountGroup, List<AccountModel>)> grouped = <(AccountGroup, List<AccountModel>)>[].obs;
  final RxInt netWorth = 0.obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  void refresh() {
    final byCode = _accounts.grouped();
    final groups = _groups.all();
    final known = groups.map((g) => g.code).toSet();
    // Accounts in a group deleted on another device land in "Lainnya".
    final orphans = [
      for (final e in byCode.entries)
        if (!known.contains(e.key)) ...e.value,
    ];
    grouped.assignAll([
      for (final g in groups)
        if ((byCode[g.code]?.isNotEmpty ?? false) || (g.code == _other && orphans.isNotEmpty))
          (g, [...?byCode[g.code], if (g.code == _other) ...orphans]),
    ]);
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

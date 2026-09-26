import 'package:get/get.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/repositories/account_group_repository.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';

class CategoriesController extends GetxController {
  final repository = TxCategoryRepository();
  final _groups = AccountGroupRepository();
  final _accounts = AccountRepository();

  final RxList<TxCategoryModel> expenseRoots = <TxCategoryModel>[].obs;
  final RxList<TxCategoryModel> incomeRoots = <TxCategoryModel>[].obs;
  final RxList<AccountGroup> accountGroups = <AccountGroup>[].obs;

  /// Accounts per group code, for the "n akun" counts.
  final RxMap<int, int> accountCounts = <int, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  @override
  void refresh() {
    expenseRoots.assignAll(repository.roots(1));
    incomeRoots.assignAll(repository.roots(0));
    accountGroups.assignAll(_groups.all());
    accountCounts.assignAll({for (final e in _accounts.grouped(includeArchived: true).entries) e.key: e.value.length});
  }

  List<TxCategoryModel> childrenOf(String id) => repository.childrenOf(id);

  /// Transactions tagged with [id] or any of its sub-categories.
  int usageCount(String id) {
    final ids = {id, ...childrenOf(id).map((c) => c.id)};
    return TxRepository().all().where((t) => t.categoryId != null && ids.contains(t.categoryId)).length;
  }

  Future<void> save(TxCategoryModel category) async {
    if (category.orderSeq == 0 && repository.byId(category.id) == null) {
      // New rows go last instead of jumping to the top.
      final siblings = category.isSub ? childrenOf(category.parentId!) : repository.roots(category.typeCode);
      category.orderSeq = siblings.fold<int>(0, (m, c) => c.orderSeq > m ? c.orderSeq : m) + 1;
    }
    await repository.upsert(category);
    refresh();
  }

  /// Deletes a category together with its sub-categories.
  Future<void> delete(String id) async {
    for (final child in childrenOf(id)) {
      await repository.delete(child.id);
    }
    await repository.delete(id);
    refresh();
  }

  /// Moves a category one step up (-1) or down (+1) among its siblings.
  Future<void> move(TxCategoryModel category, int delta) async {
    final siblings = category.isSub ? childrenOf(category.parentId!) : repository.roots(category.typeCode);
    final i = siblings.indexWhere((c) => c.id == category.id);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= siblings.length) return;
    final ids = siblings.map((c) => c.id).toList();
    ids.insert(j, ids.removeAt(i));
    await repository.reorder(ids);
    // reorder() saves through HiveObject.save, which skips updatedAt; bump
    // it so the new order syncs.
    for (final id in ids) {
      final c = repository.byId(id);
      if (c != null) await repository.upsert(c);
    }
    refresh();
  }

  // --- account groups

  Future<void> saveGroup(AccountGroup group) async {
    await _groups.save(group);
    refresh();
  }

  Future<void> createGroup({required String label, required String icon, required bool isLiabilityDefault}) async {
    await _groups.create(label: label, icon: icon, isLiabilityDefault: isLiabilityDefault);
    refresh();
  }

  Future<void> resetGroup(int code) async {
    await _groups.resetBuiltIn(code);
    refresh();
  }

  /// Deletes a user-defined group, moving its accounts to "Lainnya".
  Future<void> deleteGroup(int code) async {
    for (final a in _accounts.all(includeArchived: true, includeDeleted: true)) {
      if (a.groupCode == code) await _moveAccount(a, AccountGroupType.other.code);
    }
    await _groups.delete(code);
    refresh();
  }

  Future<void> moveGroup(AccountGroup group, int delta) async {
    final codes = accountGroups.map((g) => g.code).toList();
    final i = codes.indexOf(group.code);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= codes.length) return;
    codes.insert(j, codes.removeAt(i));
    await _groups.reorder(codes);
    refresh();
  }

  Future<void> _moveAccount(AccountModel a, int code) async {
    a.groupCode = code;
    await _accounts.upsert(a);
  }
}

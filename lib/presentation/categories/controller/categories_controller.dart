import 'package:get/get.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';

class CategoriesController extends GetxController {
  final repository = TxCategoryRepository();

  final RxList<TxCategoryModel> expenseRoots = <TxCategoryModel>[].obs;
  final RxList<TxCategoryModel> incomeRoots = <TxCategoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  void refresh() {
    expenseRoots.assignAll(repository.roots(1));
    incomeRoots.assignAll(repository.roots(0));
  }

  List<TxCategoryModel> childrenOf(String id) => repository.childrenOf(id);

  Future<void> save(TxCategoryModel category) async {
    await repository.upsert(category);
    refresh();
  }

  Future<void> delete(String id) async {
    await repository.delete(id);
    refresh();
  }
}

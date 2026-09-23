import 'package:get/get.dart';
import 'package:financial_recording/data/models/memo_model/memo_model.dart';
import 'package:financial_recording/data/repositories/memo_repository.dart';

class MemoController extends GetxController {
  final _repo = MemoRepository();
  final RxList<MemoModel> memos = <MemoModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  @override
  void refresh() => memos.assignAll(_repo.all());

  Future<void> save(MemoModel memo) async {
    await _repo.upsert(memo);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    refresh();
  }
}

import 'package:get/get.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/repositories/recurring_repository.dart';
import 'package:financial_recording/data/services/recurring_service.dart';

class RecurringController extends GetxController {
  final repository = RecurringRepository();
  final service = RecurringService();

  final RxList<RecurringRuleModel> rules = <RecurringRuleModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  void refresh() => rules.assignAll(repository.all());

  Future<void> save(RecurringRuleModel rule) async {
    await repository.upsert(rule);
    refresh();
  }

  Future<void> toggleActive(RecurringRuleModel rule) async {
    rule.isActive = !rule.isActive;
    await repository.upsert(rule);
    refresh();
  }

  Future<void> delete(String id) async {
    await repository.delete(id);
    refresh();
  }

  Future<void> confirmPost(String id) async {
    await service.confirmPost(id);
    refresh();
  }
}

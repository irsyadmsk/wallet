import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/template_model/template_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

class QuickTemplateRepository {
  Box<QuickTemplateModel> get _box => Hive.box<QuickTemplateModel>(AppBoxes.templates);

  List<QuickTemplateModel> all() {
    final list = _box.values.toList();
    list.sort((a, b) => a.orderSeq.compareTo(b.orderSeq));
    return list;
  }

  QuickTemplateModel? byId(String id) {
    try {
      return _box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsert(QuickTemplateModel template) async {
    final key = _keyFor(template.id);
    if (key != null) {
      await _box.put(key, template);
    } else {
      await _box.add(template);
    }
  }

  Future<void> delete(String id) async {
    final key = _keyFor(id);
    if (key != null) await _box.delete(key);
    await TombstoneService().record('templates', id);
  }

  /// Returns true when the defaults were written.
  Future<bool> seedDefaultsIfEmpty() async {
    if (_box.isNotEmpty) return false;

    final accounts = AccountRepository().all();
    final defaultAccount = accounts.isNotEmpty ? accounts.first.id : null;

    final categories = TxCategoryRepository().all();
    final foodCat = categories.where((c) => c.name.toLowerCase().contains('makan') || c.name.toLowerCase().contains('food')).firstOrNull?.id;
    final transportCat = categories.where((c) => c.name.toLowerCase().contains('transport') || c.name.toLowerCase().contains('bensin')).firstOrNull?.id;

    final defaults = [
      QuickTemplateModel(
        id: 'tmpl_kopi',
        name: 'Kopi',
        type: TxType.expense,
        amount: 22000,
        categoryId: foodCat,
        accountId: defaultAccount,
        iconName: 'coffee',
        colorValue: 0xFF8D6E63,
        orderSeq: 0,
      ),
      QuickTemplateModel(
        id: 'tmpl_makan',
        name: 'Makan Siang',
        type: TxType.expense,
        amount: 35000,
        categoryId: foodCat,
        accountId: defaultAccount,
        iconName: 'restaurant',
        colorValue: 0xFFEF5350,
        orderSeq: 1,
      ),
      QuickTemplateModel(
        id: 'tmpl_bensin',
        name: 'Bensin Motor',
        type: TxType.expense,
        amount: 30000,
        categoryId: transportCat,
        accountId: defaultAccount,
        iconName: 'local_gas_station',
        colorValue: 0xFFFFA726,
        orderSeq: 2,
      ),
      QuickTemplateModel(
        id: 'tmpl_parkir',
        name: 'Parkir',
        type: TxType.expense,
        amount: 5000,
        categoryId: transportCat,
        accountId: defaultAccount,
        iconName: 'local_parking',
        colorValue: 0xFF78909C,
        orderSeq: 3,
      ),
    ];

    for (final t in defaults) {
      await upsert(t);
    }
    return true;
  }

  Future<void> clear() => _box.clear();

  dynamic _keyFor(String id) {
    for (final key in _box.keys) {
      if (_box.get(key)?.id == id) return key;
    }
    return null;
  }
}

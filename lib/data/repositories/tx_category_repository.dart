import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';

class TxCategoryRepository {
  Box<TxCategoryModel> get _box => Hive.box<TxCategoryModel>(AppBoxes.categories);

  List<TxCategoryModel> all({bool includeArchived = false}) {
    final list = _box.values.where((c) => includeArchived || !c.isArchived).toList();
    list.sort((a, b) => a.orderSeq.compareTo(b.orderSeq));
    return list;
  }

  List<TxCategoryModel> byType(int typeCode, {bool includeArchived = false}) =>
      all(includeArchived: includeArchived).where((c) => c.typeCode == typeCode).toList();

  List<TxCategoryModel> roots(int typeCode) =>
      byType(typeCode).where((c) => !c.isSub).toList();

  List<TxCategoryModel> childrenOf(String parentId) =>
      all().where((c) => c.parentId == parentId).toList();

  TxCategoryModel? byId(String id) {
    try {
      return _box.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Category display name including its parent, e.g. "Makanan • Makan siang".
  String pathName(String id) {
    final c = byId(id);
    if (c == null) return '(Tanpa kategori)';
    if (c.parentId == null) return c.displayName;
    final parent = byId(c.parentId!);
    return parent == null ? c.displayName : '${parent.displayName} • ${c.name}';
  }

  Future<void> upsert(TxCategoryModel category) async {
    category.updatedAt = DateTime.now();
    final key = _keyFor(category.id);
    if (key != null) {
      await _box.put(key, category);
    } else {
      await _box.add(category);
    }
  }

  Future<void> delete(String id) async {
    final key = _keyFor(id);
    if (key != null) await _box.delete(key);
  }

  Future<void> reorder(List<String> idsInOrder) async {
    for (var i = 0; i < idsInOrder.length; i++) {
      final c = byId(idsInOrder[i]);
      if (c != null) {
        c.orderSeq = i;
        await c.save();
      }
    }
  }

  Future<void> clear() => _box.clear();

  dynamic _keyFor(String id) {
    for (final key in _box.keys) {
      if (_box.get(key)?.id == id) return key;
    }
    return null;
  }
}

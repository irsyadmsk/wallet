import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/tag_model/tag_model.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';

class TagRepository {
  Box<TagModel> get _box => Hive.box<TagModel>(AppBoxes.tags);

  List<TagModel> all({bool includeArchived = false}) =>
      _box.values.where((t) => includeArchived || !t.isArchived).toList()
        ..sort((a, b) => a.orderSeq.compareTo(b.orderSeq));

  TagModel? byId(String id) {
    try {
      return _box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsert(TagModel tag) async {
    final key = _keyFor(tag.id);
    if (key != null) {
      await _box.put(key, tag);
    } else {
      await _box.add(tag);
    }
  }

  Future<void> delete(String id) async {
    final key = _keyFor(id);
    if (key != null) await _box.delete(key);
    await TombstoneService().record('tags', id);
  }

  Future<void> clear() => _box.clear();

  dynamic _keyFor(String id) {
    for (final key in _box.keys) {
      if (_box.get(key)?.id == id) return key;
    }
    return null;
  }
}

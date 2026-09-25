import 'package:hive/hive.dart';
import 'package:financial_recording/data/repositories/box_id_index.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/memo_model/memo_model.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';

class MemoRepository {
  Box<MemoModel> get _box => Hive.box<MemoModel>(AppBoxes.memos);
  BoxIdIndex<MemoModel> get _index => BoxIdIndex.of(_box, (v) => v.id);

  List<MemoModel> all() {
    final list = _box.values.toList();
    list.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.date.compareTo(a.date);
    });
    return list;
  }

  List<MemoModel> forDate(DateTime date) => _box.values
      .where((m) => m.date.year == date.year && m.date.month == date.month && m.date.day == date.day)
      .toList();

  MemoModel? byId(String id) => _index.valueFor(_box, id);

  Future<void> upsert(MemoModel memo) async {
    memo.updatedAt = DateTime.now();
    final key = _keyFor(memo.id);
    if (key != null) {
      await _box.put(key, memo);
    } else {
      await _box.add(memo);
    }
  }

  Future<void> delete(String id) async {
    final key = _keyFor(id);
    if (key != null) await _box.delete(key);
    await TombstoneService().record('memos', id);
  }

  Future<void> clear() => _box.clear();

  dynamic _keyFor(String id) => _index.keyFor(_box, id, strict: true);
}

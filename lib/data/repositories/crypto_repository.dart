import 'package:hive/hive.dart';
import 'package:financial_recording/data/repositories/box_id_index.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/crypto_model/crypto_holding_model.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';

class CryptoRepository {
  Box<CryptoHoldingModel> get _box => Hive.box<CryptoHoldingModel>(AppBoxes.crypto);
  BoxIdIndex<CryptoHoldingModel> get _index => BoxIdIndex.of(_box, (v) => v.id);

  List<CryptoHoldingModel> all() {
    final list = _box.values.toList();
    list.sort((a, b) => a.orderSeq != b.orderSeq ? a.orderSeq.compareTo(b.orderSeq) : a.name.compareTo(b.name));
    return list;
  }

  CryptoHoldingModel? byId(String id) => _index.valueFor(_box, id);

  /// The existing holding of [coinId], if any — adding the same coin twice
  /// tops up that holding instead of creating a duplicate row.
  CryptoHoldingModel? byCoin(String coinId) {
    for (final h in _box.values) {
      if (h.coinId == coinId) return h;
    }
    return null;
  }

  Future<void> upsert(CryptoHoldingModel holding) async {
    holding.updatedAt = DateTime.now();
    final key = _keyFor(holding.id);
    if (key != null) {
      await _box.put(key, holding);
    } else {
      holding.orderSeq = _box.length;
      await _box.add(holding);
    }
  }

  Future<void> remove(String id) async {
    final key = _keyFor(id);
    if (key != null) await _box.delete(key);
    await TombstoneService().record('crypto_holdings', id);
  }

  Future<void> clear() => _box.clear();

  dynamic _keyFor(String id) => _index.keyFor(_box, id, strict: true);
}

import 'package:hive/hive.dart';

/// Cached `id → Hive key` lookup for a box whose values carry a string id.
///
/// Every repository used to find a row by scanning the whole box, so each
/// `byId`/`put` cost O(n) and a transaction list called it several times per
/// tile. The index is rebuilt lazily, only when the box may have changed
/// shape: another box instance, a different length, or a watch event. A hit
/// is always verified against the live value, so a stale cache can never
/// return a wrong key.
class BoxIdIndex<T> {
  BoxIdIndex(this._idOf);

  final String Function(T value) _idOf;

  Box<T>? _box;
  final Map<String, dynamic> _keys = {};
  int _length = -1;
  bool _dirty = true;

  static final _indexes = <String, BoxIdIndex>{};

  /// Shared index for [box], so every repository instance reuses one cache.
  static BoxIdIndex<T> of<T>(Box<T> box, String Function(T value) idOf) {
    final existing = _indexes[box.name];
    if (existing is BoxIdIndex<T>) return existing;
    return _indexes[box.name] = BoxIdIndex<T>(idOf);
  }

  void _attach(Box<T> box) {
    if (identical(_box, box)) return;
    _box = box;
    _dirty = true;
    // Adds, deletes and clears arrive here; puts on an existing key keep
    // the mapping valid but marking dirty is cheap and keeps it simple.
    box.watch().listen((_) => _dirty = true);
  }

  void _rebuild(Box<T> box) {
    _keys.clear();
    for (final key in box.keys) {
      final v = box.get(key);
      if (v != null) _keys[_idOf(v)] = key;
    }
    _length = box.length;
    _dirty = false;
  }

  /// Hive key holding [id], or null when no row has it.
  ///
  /// A miss is trusted while the index looks current, which keeps reads of
  /// dangling ids cheap. Writers pass [strict] so a miss is always confirmed
  /// against a fresh index — a false miss there would insert a duplicate.
  dynamic keyFor(Box<T> box, String id, {bool strict = false}) {
    _attach(box);
    var rebuilt = false;
    if (_dirty || _length != box.length) {
      _rebuild(box);
      rebuilt = true;
    }
    final key = _keys[id];
    if (key != null) {
      final v = box.get(key);
      if (v != null && _idOf(v) == id) return key;
    }
    if (rebuilt || (!strict && key == null)) return null;
    _rebuild(box);
    return _keys[id];
  }

  T? valueFor(Box<T> box, String id) {
    final key = keyFor(box, id);
    return key == null ? null : box.get(key);
  }
}

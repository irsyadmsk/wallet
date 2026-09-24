import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

/// Learns categories from the ledger's own history: an exact memo match
/// wins; otherwise each meaningful word in the memo votes for the
/// categories it appeared with before. Only confident guesses are returned.
abstract class CategorySuggester {
  static const _stop = {'dan', 'di', 'ke', 'untuk', 'yang', 'the', 'bayar', 'beli', 'dari'};

  static List<String> _words(String s) => s
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length >= 3 && !_stop.contains(w))
      .toList();

  static String? suggest(String memo, TxType type, Iterable<TxModel> history) {
    final q = memo.trim().toLowerCase();
    if (q.length < 3 || type == TxType.transfer) return null;

    final exact = <String, int>{};
    final votes = <String, double>{};
    final support = <String, int>{};
    final words = _words(q).toSet();
    for (final t in history) {
      if (t.type != type || t.categoryId == null) continue;
      final m = t.memo?.trim().toLowerCase();
      if (m == null || m.isEmpty) continue;
      if (m == q) exact[t.categoryId!] = (exact[t.categoryId!] ?? 0) + 1;
      if (words.isEmpty) continue;
      final hit = _words(m).where(words.contains).length;
      if (hit > 0) {
        votes[t.categoryId!] = (votes[t.categoryId!] ?? 0) + hit / words.length;
        support[t.categoryId!] = (support[t.categoryId!] ?? 0) + 1;
      }
    }

    if (exact.isNotEmpty) {
      return (exact.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    }
    if (votes.isEmpty) return null;
    final ranked = votes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = votes.values.fold(0.0, (s, v) => s + v);
    final best = ranked.first;
    // Needs support from at least two past rows and a clear majority.
    if ((support[best.key] ?? 0) < 2 || best.value / total < 0.6) return null;
    return best.key;
  }
}

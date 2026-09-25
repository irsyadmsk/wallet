/// Plans how a member's personal ledger joins a family ledger, working on
/// the synced JSON rows (`table → rows`) so it's pure and testable.
///
/// Every personal row keeps its id — importing twice updates the same rows
/// instead of duplicating them — except shared vocabulary the family already
/// has, which is mapped onto the family's row instead of copied:
/// - categories with the same type, name and parent;
/// - tags and quick templates with the same name;
/// - accounts with the same name and group that the member never used
///   (typically the starter "Tunai" both sides got on sign-up);
/// - a budget for a category the family already budgets.
/// Crypto holdings of a coin the family already tracks are added onto the
/// family's holding.
class LedgerMerge {
  LedgerMerge._();

  /// Rows to write into the family ledger, per table.
  static Map<String, List<Map<String, dynamic>>> plan({
    required Map<String, List<Map<String, dynamic>>> mine,
    required Map<String, List<Map<String, dynamic>>> family,
  }) {
    List<Map<String, dynamic>> rows(Map<String, List<Map<String, dynamic>>> m, String t) => m[t] ?? const [];
    String norm(Object? v) => (v?.toString() ?? '').trim().toLowerCase();
    final out = <String, List<Map<String, dynamic>>>{};
    void emit(String table, Map<String, dynamic> row) => out.putIfAbsent(table, () => []).add(row);

    // --- categories (parents before children so parent ids are mapped)
    final famCats = rows(family, 'categories');
    final famCatById = {for (final c in famCats) c['id']: c};
    String catKey(Map<String, dynamic> c, Map<dynamic, Map<String, dynamic>> byId) {
      final parent = c['parentId'] == null ? null : byId[c['parentId']];
      return '${c['typeCode']}|${norm(c['name'])}|${parent == null ? '' : norm(parent['name'])}';
    }

    final famCatKeys = {for (final c in famCats) catKey(c, famCatById): c['id'] as String};
    final myCats = rows(mine, 'categories');
    final myCatById = {for (final c in myCats) c['id']: c};
    final catMap = <String, String>{};
    final orderedCats = [...myCats]..sort((a, b) => (a['parentId'] == null ? 0 : 1).compareTo(b['parentId'] == null ? 0 : 1));
    for (final c in orderedCats) {
      final match = famCatKeys[catKey(c, myCatById)];
      if (match != null) {
        catMap[c['id'] as String] = match;
      } else {
        final copy = Map<String, dynamic>.from(c);
        if (copy['parentId'] != null) copy['parentId'] = catMap[copy['parentId']] ?? copy['parentId'];
        emit('categories', copy);
      }
    }
    String? cat(Object? id) => id == null ? null : (catMap[id] ?? id as String);

    // --- tags
    final famTags = {for (final t in rows(family, 'tags')) norm(t['name']): t['id'] as String};
    final tagMap = <String, String>{};
    for (final t in rows(mine, 'tags')) {
      final match = famTags[norm(t['name'])];
      if (match != null) {
        tagMap[t['id'] as String] = match;
      } else {
        emit('tags', Map<String, dynamic>.from(t));
      }
    }

    // --- accounts: map only unused look-alikes
    final used = <Object?>{
      for (final t in rows(mine, 'transactions')) ...[t['accountId'], t['toAccountId']],
      for (final r in rows(mine, 'recurring')) ...[r['accountId'], r['toAccountId']],
    };
    final famAccs = {
      for (final a in rows(family, 'accounts'))
        if (a['deletedAt'] == null) '${norm(a['name'])}|${a['groupCode']}': a['id'] as String,
    };
    final accMap = <String, String>{};
    for (final a in rows(mine, 'accounts')) {
      final match = famAccs['${norm(a['name'])}|${a['groupCode']}'];
      final opening = (a['openingBalance'] as num?)?.toInt() ?? 0;
      if (match != null && !used.contains(a['id']) && opening == 0) {
        accMap[a['id'] as String] = match;
      } else {
        emit('accounts', Map<String, dynamic>.from(a));
      }
    }
    String? acc(Object? id) => id == null ? null : (accMap[id] ?? id as String);

    // --- transactions
    for (final t in rows(mine, 'transactions')) {
      emit('transactions', {
        ...t,
        'accountId': acc(t['accountId']),
        'toAccountId': acc(t['toAccountId']),
        'categoryId': cat(t['categoryId']),
        if (t['tagIds'] is List) 'tagIds': [for (final id in t['tagIds'] as List) tagMap[id] ?? id],
      });
    }

    // --- recurring rules
    for (final r in rows(mine, 'recurring')) {
      emit('recurring', {
        ...r,
        'accountId': acc(r['accountId']),
        'toAccountId': acc(r['toAccountId']),
        'categoryId': cat(r['categoryId']),
      });
    }

    // --- quick templates: skip names the family already has
    final famTemplates = {for (final t in rows(family, 'templates')) norm(t['name'])};
    for (final t in rows(mine, 'templates')) {
      if (famTemplates.contains(norm(t['name']))) continue;
      emit('templates', {...t, 'accountId': acc(t['accountId']), 'categoryId': cat(t['categoryId'])});
    }

    // --- budgets: one per category (or one total) is enough
    final famBudgets = {for (final b in rows(family, 'budgets')) b['isTotal'] == true ? '*' : b['categoryId']};
    for (final b in rows(mine, 'budgets')) {
      final key = b['isTotal'] == true ? '*' : cat(b['categoryId']);
      if (famBudgets.contains(key)) continue;
      emit('budgets', {...b, 'categoryId': cat(b['categoryId'])});
    }

    // --- crypto: top up the family's holding of the same coin
    final famCoins = {for (final h in rows(family, 'crypto_holdings')) h['coinId']: h};
    for (final h in rows(mine, 'crypto_holdings')) {
      final match = famCoins[h['coinId']];
      if (match == null) {
        emit('crypto_holdings', Map<String, dynamic>.from(h));
      } else if (match['id'] != h['id']) {
        emit('crypto_holdings', {
          ...match,
          'amount': ((match['amount'] as num?) ?? 0) + ((h['amount'] as num?) ?? 0),
          'costBasis': ((match['costBasis'] as num?) ?? 0) + ((h['costBasis'] as num?) ?? 0),
        });
      }
    }

    // --- everything else is personal and copied as-is
    for (final table in const ['goals', 'debts', 'memos']) {
      for (final r in rows(mine, table)) {
        emit(table, Map<String, dynamic>.from(r));
      }
    }
    return out;
  }
}

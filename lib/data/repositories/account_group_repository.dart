import 'dart:math';

import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';

/// An account group as the user sees it: a built-in [AccountGroupType] with
/// any renaming applied, or a group the user created.
class AccountGroup {
  const AccountGroup({
    required this.code,
    required this.label,
    required this.icon,
    required this.isLiabilityDefault,
    required this.builtIn,
    this.hidden = false,
    this.order = 0,
  });

  /// Stored on every [AccountModel.groupCode]; never changes.
  final int code;
  final String label;
  final String icon;
  final bool isLiabilityDefault;
  final bool builtIn;

  /// Left out of the group picker (accounts already in it still show).
  final bool hidden;
  final int order;

  AccountGroup copyWith({String? label, String? icon, bool? isLiabilityDefault, bool? hidden, int? order}) => AccountGroup(
        code: code,
        label: label ?? this.label,
        icon: icon ?? this.icon,
        isLiabilityDefault: isLiabilityDefault ?? this.isLiabilityDefault,
        builtIn: builtIn,
        hidden: hidden ?? this.hidden,
        order: order ?? this.order,
      );
}

/// Account groups are editable like categories. They're stored as rows in
/// the categories box with [TxCategoryModel.accountGroupType], so they sync
/// through the existing `categories` table with no schema change:
/// - id `accgroup-<code>` (deterministic, so devices converge on one row);
/// - `name`/`emoji` = label/icon, `orderSeq` = order, `isArchived` = hidden;
/// - `iconPath == 'liability'` marks a group whose accounts default to debt.
///
/// Built-in groups without a row fall back to their [AccountGroupType]
/// defaults.
class AccountGroupRepository {
  AccountGroupRepository([TxCategoryRepository? categories]) : _categories = categories ?? TxCategoryRepository();
  final TxCategoryRepository _categories;

  static const _prefix = 'accgroup-';
  static const _liabilityMark = 'liability';

  /// Every group, in display order. [includeHidden] also returns groups the
  /// user hid from the picker.
  List<AccountGroup> all({bool includeHidden = true}) {
    // Before the boxes open (widget tests, early startup) only the built-ins exist.
    final stored = Hive.isBoxOpen(AppBoxes.categories)
        ? _categories.byType(TxCategoryModel.accountGroupType, includeArchived: true)
        : const <TxCategoryModel>[];
    final rows = {
      for (final c in stored)
        if (_codeOf(c) != null) _codeOf(c)!: c,
    };
    final result = <AccountGroup>[];
    for (var i = 0; i < AccountGroupType.displayOrder.length; i++) {
      final g = AccountGroupType.displayOrder[i];
      final row = rows.remove(g.code);
      result.add(row == null ? _builtIn(g, i) : _fromRow(row, builtIn: true));
    }
    for (final row in rows.values) {
      result.add(_fromRow(row, builtIn: false));
    }
    result.sort((a, b) => a.order.compareTo(b.order));
    return includeHidden ? result : result.where((g) => !g.hidden).toList();
  }

  AccountGroup of(int code) {
    for (final g in all()) {
      if (g.code == code) return g;
    }
    // A code from a group deleted on another device: show it as "Lainnya".
    return all().firstWhere((g) => g.code == AccountGroupType.other.code);
  }

  Future<void> save(AccountGroup group) async {
    final id = '$_prefix${group.code}';
    final row = _categories.byId(id) ??
        TxCategoryModel(id: id, name: group.label, typeCode: TxCategoryModel.accountGroupType);
    row
      ..name = group.label.trim()
      ..emoji = group.icon.trim()
      ..orderSeq = group.order
      ..isArchived = group.hidden
      ..iconPath = group.isLiabilityDefault ? _liabilityMark : null;
    await _categories.upsert(row);
  }

  /// A new user-defined group, placed last. Codes are random rather than
  /// "max + 1" so two devices adding a group offline never collide.
  Future<AccountGroup> create({required String label, required String icon, bool isLiabilityDefault = false}) async {
    final taken = all().map((g) => g.code).toSet();
    final rng = Random();
    var code = 0;
    while (code == 0 || taken.contains(code)) {
      code = 1000 + rng.nextInt(1 << 30);
    }
    final group = AccountGroup(
      code: code,
      label: label,
      icon: icon,
      isLiabilityDefault: isLiabilityDefault,
      builtIn: false,
      order: all().fold<int>(0, (m, g) => max(m, g.order)) + 1,
    );
    await save(group);
    return group;
  }

  /// Restores a built-in group's original name and icon.
  Future<void> resetBuiltIn(int code) async {
    final g = AccountGroupType.fromCode(code);
    final current = of(code);
    await save(current.copyWith(label: g.label, icon: g.icon, isLiabilityDefault: g.isLiabilityDefault, hidden: false));
  }

  /// Deletes a user-defined group. Callers move its accounts elsewhere first.
  Future<void> delete(int code) async {
    if (AccountGroupType.values.any((g) => g.code == code)) return;
    await _categories.delete('$_prefix$code');
  }

  Future<void> reorder(List<int> codesInOrder) async {
    final byCode = {for (final g in all()) g.code: g};
    for (var i = 0; i < codesInOrder.length; i++) {
      final g = byCode[codesInOrder[i]];
      if (g != null && g.order != i) await save(g.copyWith(order: i));
    }
  }

  static int? _codeOf(TxCategoryModel row) =>
      row.id.startsWith(_prefix) ? int.tryParse(row.id.substring(_prefix.length)) : null;

  static AccountGroup _builtIn(AccountGroupType g, int order) => AccountGroup(
        code: g.code,
        label: g.label,
        icon: g.icon,
        isLiabilityDefault: g.isLiabilityDefault,
        builtIn: true,
        order: order,
      );

  static AccountGroup _fromRow(TxCategoryModel row, {required bool builtIn}) => AccountGroup(
        code: _codeOf(row)!,
        label: row.name,
        icon: (row.emoji == null || row.emoji!.isEmpty) ? '📁' : row.emoji!,
        isLiabilityDefault: row.iconPath == _liabilityMark,
        builtIn: builtIn,
        hidden: row.isArchived,
        order: row.orderSeq,
      );
}

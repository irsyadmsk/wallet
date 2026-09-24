import 'package:sqlite3/common.dart';
import 'package:financial_recording/data/import/mmbak_models.dart';

/// Reads every table the importer needs from an opened `.mmbak` database.
/// Shared by the native reader (`dart:ffi`) and the web reader (WASM), so
/// both platforms see exactly the same rows.
MmbakRawData readMmbakTables(CommonDatabase db) {
  return MmbakRawData(
    assetGroups: _select(db, 'SELECT * FROM ASSETGROUP'),
    assets: _select(db, 'SELECT * FROM ASSETS'),
    categories: _select(db, 'SELECT * FROM ZCATEGORY'),
    transactions: _select(
      db,
      "SELECT * FROM INOUTCOME WHERE IS_DEL = 0 OR IS_DEL IS NULL",
    ),
    tags: _selectSafe(db, 'SELECT * FROM TAG'),
    txTags: _selectSafe(db, 'SELECT * FROM TX_TAG'),
    budgets: _selectSafe(db, 'SELECT * FROM BUDGET'),
    budgetAmounts: _selectSafe(db, 'SELECT * FROM BUDGET_AMOUNT'),
    repeatTransactions: _selectSafe(db, 'SELECT * FROM REPEATTRANSACTION'),
  );
}

List<Map<String, Object?>> _select(CommonDatabase db, String sql) {
  final result = db.select(sql);
  return result.map((row) => Map<String, Object?>.from(row)).toList();
}

/// Some tables may not exist in older backup schema versions — degrade
/// gracefully instead of failing the whole import.
List<Map<String, Object?>> _selectSafe(CommonDatabase db, String sql) {
  try {
    return _select(db, sql);
  } catch (_) {
    return [];
  }
}

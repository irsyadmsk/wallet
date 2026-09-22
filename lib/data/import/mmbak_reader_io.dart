import 'package:sqlite3/sqlite3.dart';
import 'package:financial_recording/data/import/mmbak_models.dart';

/// Native (Android/iOS/Windows/macOS/Linux) reader for the `.mmbak` file,
/// which is a raw SQLite3 database (Money Manager app backup format).
class MmbakReader {
  static bool get isSupported => true;

  static Future<MmbakRawData> read(String filePath) async {
    final db = sqlite3.open(filePath, mode: OpenMode.readOnly);
    try {
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
    } finally {
      db.dispose();
    }
  }

  static List<Map<String, Object?>> _select(Database db, String sql) {
    final result = db.select(sql);
    return result.map((row) => Map<String, Object?>.from(row)).toList();
  }

  /// Some tables may not exist in older backup schema versions — degrade
  /// gracefully instead of failing the whole import.
  static List<Map<String, Object?>> _selectSafe(Database db, String sql) {
    try {
      return _select(db, sql);
    } catch (_) {
      return [];
    }
  }
}

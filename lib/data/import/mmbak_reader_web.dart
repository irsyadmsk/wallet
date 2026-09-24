import 'dart:typed_data';

import 'package:sqlite3/wasm.dart';
import 'package:financial_recording/data/import/mmbak_models.dart';
import 'package:financial_recording/data/import/mmbak_reader_common.dart';

/// Web reader for `.mmbak` (a raw SQLite3 database). The browser has no
/// `dart:ffi`, so SQLite runs as WebAssembly (`web/sqlite3.wasm`, taken from
/// the sqlite3.dart release matching the package version in pubspec.lock)
/// over an in-memory file system — the backup never leaves the browser.
class MmbakReader {
  static bool get isSupported => true;

  static WasmSqlite3? _sqlite;
  static const _dbPath = '/impor.mmbak';

  static Future<MmbakRawData> read({String? path, Uint8List? bytes}) async {
    if (bytes == null) {
      throw ArgumentError('Di web, isi berkas (bytes) wajib diberikan.');
    }
    // Absolute path so deep links like /masuk don't resolve it to
    // /masuk/sqlite3.wasm (the SPA fallback would answer with index.html).
    final sqlite = _sqlite ??= await WasmSqlite3.loadFromUrl(Uri.parse('/sqlite3.wasm'));

    final fs = InMemoryFileSystem();
    sqlite.registerVirtualFileSystem(fs, makeDefault: true);
    final opened = fs.xOpen(
      Sqlite3Filename(_dbPath),
      SqlFlag.SQLITE_OPEN_CREATE | SqlFlag.SQLITE_OPEN_READWRITE,
    );
    opened.file
      ..xWrite(bytes, 0)
      ..xClose();

    final db = sqlite.open(_dbPath, mode: OpenMode.readOnly);
    try {
      return readMmbakTables(db);
    } finally {
      db.dispose();
      sqlite.unregisterVirtualFileSystem(fs);
    }
  }
}

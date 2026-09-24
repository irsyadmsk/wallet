import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';
import 'package:financial_recording/data/import/mmbak_models.dart';
import 'package:financial_recording/data/import/mmbak_reader_common.dart';

/// Native (Android/iOS/Windows/macOS/Linux) reader for the `.mmbak` file,
/// which is a raw SQLite3 database (Money Manager app backup format).
class MmbakReader {
  static bool get isSupported => true;

  /// Reads from [path] when given; otherwise writes [bytes] to a temporary
  /// file first (some pickers only hand back bytes).
  static Future<MmbakRawData> read({String? path, Uint8List? bytes}) async {
    File? temp;
    if (path == null) {
      if (bytes == null) throw ArgumentError('path atau bytes wajib diisi');
      temp = File('${Directory.systemTemp.path}/impor-${DateTime.now().microsecondsSinceEpoch}.mmbak');
      await temp.writeAsBytes(bytes, flush: true);
      path = temp.path;
    }
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      return readMmbakTables(db);
    } finally {
      db.dispose();
      if (temp != null && temp.existsSync()) temp.deleteSync();
    }
  }
}

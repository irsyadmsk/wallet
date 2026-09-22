import 'package:financial_recording/data/import/mmbak_models.dart';

/// Web fallback — `package:sqlite3` needs `dart:ffi`, which doesn't exist on
/// web. This file must NOT import `dart:ffi`/`dart:io`/`package:sqlite3` so
/// the web build tree stays compilable; see `mmbak_reader.dart`'s
/// conditional export.
class MmbakReader {
  static bool get isSupported => false;

  static Future<MmbakRawData> read(String filePath) {
    throw UnsupportedError(
      'Impor .mmbak hanya didukung di build mobile/desktop (bukan web). '
      'Gunakan menu Pengaturan > Pulihkan cadangan (JSON) sebagai gantinya.',
    );
  }
}

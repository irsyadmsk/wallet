import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service for handling receipt/bill attachments:
/// picking, storing permanently in the app's internal documents sandbox,
/// and cleaning up files when transactions are deleted.
class ReceiptService {
  ReceiptService();

  static final _rnd = Random();

  /// Whether each receipt path exists, remembered so list tiles don't hit
  /// the disk synchronously on every build. Receipts are only ever written
  /// or deleted through this service, which keeps the cache current.
  static final Map<String, bool> _existsCache = {};

  /// Cached, synchronous existence check for rendering.
  static bool receiptExistsCached(String? path) {
    if (path == null || path.isEmpty || kIsWeb) return false;
    return _existsCache[path] ??= File(path).existsSync();
  }

  /// Prompts user to pick an image file (PNG, JPG, JPEG, WEBP, HEIC, etc.)
  Future<String?> pickReceiptImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final pickedPath = result.files.single.path;
      if (pickedPath == null || pickedPath.isEmpty) {
        return null;
      }

      return pickedPath;
    } catch (e) {
      return null;
    }
  }

  /// Copies the picked file to the application's permanent `receipts` folder.
  /// Returns the persistent local file path.
  Future<String> saveReceiptPermanently(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('File gambar struk tidak ditemukan', sourcePath);
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(appDocDir.path, 'receipts'));
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath).toLowerCase();
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final randomSuffix = _rnd.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final fileName = 'receipt_${DateTime.now().microsecondsSinceEpoch}_$randomSuffix$safeExt';
    final targetPath = p.join(receiptsDir.path, fileName);

    final savedFile = await sourceFile.copy(targetPath);
    _existsCache[savedFile.path] = true;
    return savedFile.path;
  }

  /// Safely deletes a receipt file from disk if it exists.
  Future<void> deleteReceipt(String? path) async {
    if (path == null || path.isEmpty) return;
    _existsCache.remove(path);
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore deletion errors gracefully
    }
  }

  /// Checks whether a receipt image exists at the given path.
  bool receiptExists(String? path) {
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }
}

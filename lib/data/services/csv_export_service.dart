import 'dart:convert';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';

/// Prompts a save-file dialog and writes [content] to it. Shared by every
/// screen that exports CSV/text so the file_picker + dart:io dance lives in
/// one place.
Future<bool> saveTextFile(String content, {required String fileName, String? dialogTitle}) async {
  final bytes = Uint8List.fromList(utf8.encode(content));
  final path = await FilePicker.platform.saveFile(
    dialogTitle: dialogTitle ?? 'Simpan file',
    fileName: fileName,
    bytes: bytes,
  );
  if (path == null) return false;
  if (!kIsWeb) {
    await io.File(path).writeAsString(content);
  }
  return true;
}

/// Builds a CSV string of transactions (all, or a caller-supplied filtered
/// list) — hand the result to `file_picker` to save.
class CsvExportService {
  String buildCsv([List<TxModel>? transactions]) {
    final accounts = AccountRepository();
    final categories = TxCategoryRepository();
    final txs = (transactions ?? TxRepository().all()).toList()..sort((a, b) => a.date.compareTo(b.date));

    final buffer = StringBuffer('Tanggal,Jenis,Akun,Akun Tujuan,Kategori,Jumlah,Catatan\n');
    final df = DateFormat('yyyy-MM-dd HH:mm');
    for (final t in txs) {
      final account = accounts.byId(t.accountId)?.name ?? '';
      final toAccount = t.toAccountId == null ? '' : (accounts.byId(t.toAccountId!)?.name ?? '');
      final category = t.categoryId == null ? '' : categories.pathName(t.categoryId!);
      final memo = (t.memo ?? '').replaceAll(',', ' ').replaceAll('\n', ' ');
      buffer.writeln('${df.format(t.date)},${t.type.name},$account,$toAccount,$category,${t.amount},$memo');
    }
    return buffer.toString();
  }
}

import 'dart:convert';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:financial_recording/data/services/backup_service.dart';
import 'package:financial_recording/data/services/csv_export_service.dart';
import 'package:financial_recording/data/services/ledger_service.dart';

class SettingsController extends GetxController {
  final _backup = BackupService();
  final _ledger = LedgerService();
  final RxBool busy = false.obs;
  final RxString lastMessage = ''.obs;

  Future<void> exportBackup() async {
    busy.value = true;
    try {
      final jsonStr = _backup.exportJson();
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan cadangan',
        fileName: 'money_manager_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        bytes: bytes,
      );
      if (path != null && !kIsWeb) {
        await io.File(path).writeAsString(jsonStr);
      }
      lastMessage.value = 'Cadangan berhasil disimpan.';
    } catch (e) {
      lastMessage.value = 'Gagal menyimpan cadangan: $e';
    } finally {
      busy.value = false;
    }
  }

  Future<void> exportCsv() async {
    busy.value = true;
    try {
      final csv = CsvExportService().buildCsv();
      await saveTextFile(
        csv,
        dialogTitle: 'Ekspor CSV',
        fileName: 'transaksi_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      lastMessage.value = 'Ekspor CSV berhasil.';
    } catch (e) {
      lastMessage.value = 'Gagal mengekspor CSV: $e';
    } finally {
      busy.value = false;
    }
  }

  Future<bool> restoreBackup() async {
    busy.value = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return false;
      final file = result.files.single;
      final content = file.bytes != null
          ? utf8.decode(file.bytes!)
          : await io.File(file.path!).readAsString();
      await _backup.restoreJson(content, replaceAll: true);
      lastMessage.value = 'Cadangan berhasil dipulihkan.';
      return true;
    } catch (e) {
      lastMessage.value = 'Gagal memulihkan cadangan: $e';
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<void> recomputeBalances() async {
    busy.value = true;
    try {
      await _ledger.recomputeAllBalances();
      lastMessage.value = 'Saldo berhasil dihitung ulang.';
    } finally {
      busy.value = false;
    }
  }
}

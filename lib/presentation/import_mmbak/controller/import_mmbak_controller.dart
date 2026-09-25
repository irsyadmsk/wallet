import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:financial_recording/app/app_events.dart';
import 'package:financial_recording/data/import/mmbak_import_service.dart';
import 'package:financial_recording/data/import/mmbak_models.dart';

enum ImportStep { pickFile, preview, importing, done, error }

class ImportMmbakController extends GetxController {
  final _service = MmbakImportService();

  final Rx<ImportStep> step = ImportStep.pickFile.obs;
  final RxString filePath = ''.obs;
  Uint8List? _bytes;
  final Rx<MmbakPreview?> preview = Rx<MmbakPreview?>(null);
  final Rx<ImportMode> mode = ImportMode.replaceAll.obs;
  final RxDouble progress = 0.0.obs;
  final RxString progressPhase = ''.obs;
  final Rx<MmbakImportReport?> report = Rx<MmbakImportReport?>(null);
  final RxString errorMessage = ''.obs;

  bool get isSupported => MmbakImportService.isSupportedOnThisPlatform;

  Future<void> pickAndAnalyze() async {
    // Web has no file paths — the picker hands back the file's bytes instead.
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: kIsWeb);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    _bytes = kIsWeb ? file.bytes : null;
    final path = kIsWeb ? null : file.path;
    if (_bytes == null && path == null) return;
    filePath.value = path ?? file.name;
    await analyze();
  }

  Future<void> analyze() async {
    try {
      step.value = ImportStep.preview;
      progress.value = 0;
      final p = await _service.analyze(
        path: _bytes == null ? filePath.value : null,
        bytes: _bytes,
        onProgress: (phase, frac) {
          progressPhase.value = phase;
          progress.value = frac;
        },
      );
      preview.value = p;
    } catch (e) {
      errorMessage.value = 'Gagal membaca file: $e';
      step.value = ImportStep.error;
    }
  }

  Future<void> apply() async {
    final p = preview.value;
    if (p == null) return;
    step.value = ImportStep.importing;
    try {
      final r = await _service.apply(
        p,
        mode: mode.value,
        onProgress: (phase, frac) {
          progressPhase.value = phase;
          progress.value = frac;
        },
      );
      report.value = r;
      step.value = ImportStep.done;
      // Every open screen (dashboard hero, lists, reports) reloads now,
      // not on the next app start.
      notifyDataChanged();
    } catch (e) {
      errorMessage.value = 'Gagal mengimpor: $e';
      step.value = ImportStep.error;
    }
  }

  void reset() {
    step.value = ImportStep.pickFile;
    filePath.value = '';
    _bytes = null;
    preview.value = null;
    report.value = null;
    errorMessage.value = '';
  }
}

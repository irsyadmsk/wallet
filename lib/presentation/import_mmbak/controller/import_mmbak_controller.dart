import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:financial_recording/data/import/mmbak_import_service.dart';
import 'package:financial_recording/data/import/mmbak_models.dart';

enum ImportStep { pickFile, preview, importing, done, error }

class ImportMmbakController extends GetxController {
  final _service = MmbakImportService();

  final Rx<ImportStep> step = ImportStep.pickFile.obs;
  final RxString filePath = ''.obs;
  final Rx<MmbakPreview?> preview = Rx<MmbakPreview?>(null);
  final Rx<ImportMode> mode = ImportMode.replaceAll.obs;
  final RxDouble progress = 0.0.obs;
  final RxString progressPhase = ''.obs;
  final Rx<MmbakImportReport?> report = Rx<MmbakImportReport?>(null);
  final RxString errorMessage = ''.obs;

  bool get isSupported => MmbakImportService.isSupportedOnThisPlatform;

  Future<void> pickAndAnalyze() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: false);
    if (result == null || result.files.isEmpty || result.files.single.path == null) return;
    filePath.value = result.files.single.path!;
    await analyze();
  }

  Future<void> analyze() async {
    try {
      step.value = ImportStep.preview;
      progress.value = 0;
      final p = await _service.analyze(
        filePath.value,
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
    } catch (e) {
      errorMessage.value = 'Gagal mengimpor: $e';
      step.value = ImportStep.error;
    }
  }

  void reset() {
    step.value = ImportStep.pickFile;
    filePath.value = '';
    preview.value = null;
    report.value = null;
    errorMessage.value = '';
  }
}

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Best-effort fields pulled out of a scanned receipt's OCR text. Always
/// shown to the user for confirmation before touching the form — OCR on a
/// crumpled thermal-paper receipt is unreliable enough that silently
/// trusting it would risk logging the wrong amount.
class ReceiptScanResult {
  final String rawText;
  final int? amount;
  final DateTime? date;
  final String? merchant;

  ReceiptScanResult({required this.rawText, this.amount, this.date, this.merchant});

  bool get hasAnything => amount != null || date != null || (merchant != null && merchant!.isNotEmpty);
}

/// On-device receipt OCR via Google ML Kit — Android/iOS only. On other
/// platforms (web, desktop) [isSupported] is false and callers should hide
/// the "Pindai Struk" entry point instead of invoking this service.
class ReceiptOcrService {
  final ImagePicker _picker = ImagePicker();

  static bool get isSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Opens the camera and returns the captured photo's path, or null if the
  /// user cancelled.
  Future<String?> captureFromCamera() async {
    if (!isSupported) return null;
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      maxWidth: 2400,
    );
    return file?.path;
  }

  /// Runs on-device text recognition on [imagePath] and parses it for an
  /// amount/date/merchant guess. Returns null on unsupported platforms or
  /// if recognition fails outright.
  Future<ReceiptScanResult?> scan(String imagePath) async {
    if (!isSupported) return null;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(input);
      return parseText(recognized.text);
    } catch (_) {
      return null;
    } finally {
      await recognizer.close();
    }
  }

  // --- Parsing heuristics -------------------------------------------------

  static final _totalKeywords = RegExp(
    r'(grand\s*total|total\s*bayar|total\s*belanja|total\s*tagihan|total\s*akhir|jumlah\s*bayar|jumlah\s*total|total|jumlah)',
    caseSensitive: false,
  );

  // Subtotal/tax-ish lines that should never win over an actual total.
  static final _excludeKeywords = RegExp(
    r'(sub\s*total|subtotal|diskon|discount|ppn|tax|pajak|kembali|cash|tunai|change)',
    caseSensitive: false,
  );

  static final _numberPattern = RegExp(r'\d{1,3}(?:[.,]\d{3})+|\d{4,}');

  static final _datePatterns = [
    RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})'), // dd/mm/yyyy
    RegExp(r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})'), // yyyy-mm-dd
    RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2})\b'), // dd/mm/yy
  ];

  /// Pure text-in, struct-out parsing — public (and platform-independent)
  /// so the heuristics can be unit tested without a camera or a device.
  @visibleForTesting
  ReceiptScanResult parseText(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final amount = _guessAmount(lines);
    final date = _guessDate(text);
    final merchant = _guessMerchant(lines);

    return ReceiptScanResult(rawText: text, amount: amount, date: date, merchant: merchant);
  }

  int? _parseAmount(String raw) {
    final normalized = raw.replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(normalized);
  }

  int? _guessAmount(List<String> lines) {
    final candidates = <int>[];

    for (final line in lines) {
      if (!_totalKeywords.hasMatch(line)) continue;
      if (_excludeKeywords.hasMatch(line) && !RegExp(r'\btotal\b', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      final matches = _numberPattern.allMatches(line).toList();
      if (matches.isEmpty) continue;
      final value = _parseAmount(matches.last.group(0)!);
      if (value != null && value > 0) candidates.add(value);
    }

    if (candidates.isNotEmpty) {
      // Several "total"-ish lines can appear (subtotal shown as "Total
      // Item", final "Total Bayar", etc.) — the largest is almost always
      // the actual amount paid.
      candidates.sort();
      return candidates.last;
    }

    // Fallback: no recognizable "total" label at all — take the largest
    // plausible currency-looking number anywhere on the receipt.
    final all = <int>[];
    for (final line in lines) {
      for (final m in _numberPattern.allMatches(line)) {
        final v = _parseAmount(m.group(0)!);
        if (v != null && v >= 500 && v < 500000000) all.add(v);
      }
    }
    if (all.isEmpty) return null;
    all.sort();
    return all.last;
  }

  DateTime? _guessDate(String text) {
    final now = DateTime.now();
    for (final pattern in _datePatterns) {
      final m = pattern.firstMatch(text);
      if (m == null) continue;
      try {
        int a = int.parse(m.group(1)!);
        int b = int.parse(m.group(2)!);
        int c = int.parse(m.group(3)!);
        int year, month, day;
        if (m.group(1)!.length == 4) {
          year = a;
          month = b;
          day = c;
        } else {
          day = a;
          month = b;
          year = c < 100 ? 2000 + c : c;
        }
        if (month < 1 || month > 12 || day < 1 || day > 31) continue;
        final candidate = DateTime(year, month, day);
        // Reject obviously-wrong OCR dates (far future/past).
        if (candidate.isAfter(now.add(const Duration(days: 1)))) continue;
        if (candidate.isBefore(DateTime(now.year - 5))) continue;
        return candidate;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  String? _guessMerchant(List<String> lines) {
    if (lines.isEmpty) return null;
    // The store name is almost always one of the first couple of printed
    // lines, before any address/phone-number/date noise.
    for (final line in lines.take(3)) {
      if (line.length < 3) continue;
      if (RegExp(r'^\d+$').hasMatch(line)) continue;
      if (_datePatterns.any((p) => p.hasMatch(line))) continue;
      return line;
    }
    return lines.first;
  }
}

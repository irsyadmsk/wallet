import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/data/services/receipt_service.dart';

void main() {
  group('ReceiptService tests', () {
    late ReceiptService service;
    late Directory tempDir;

    setUp(() async {
      service = ReceiptService();
      tempDir = await Directory.systemTemp.createTemp('receipt_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('receiptExists returns false for null or empty path', () {
      expect(service.receiptExists(null), isFalse);
      expect(service.receiptExists(''), isFalse);
      expect(service.receiptExists('non_existent_file.jpg'), isFalse);
    });

    test('receiptExists returns true for existing file', () async {
      final file = File('${tempDir.path}/test_receipt.jpg');
      await file.writeAsString('dummy image content');

      expect(service.receiptExists(file.path), isTrue);
    });

    test('deleteReceipt removes file if exists', () async {
      final file = File('${tempDir.path}/test_delete.jpg');
      await file.writeAsString('to be deleted');

      expect(file.existsSync(), isTrue);
      await service.deleteReceipt(file.path);
      expect(file.existsSync(), isFalse);
    });

    test('deleteReceipt does not throw if path is null or non-existent', () async {
      await expectLater(service.deleteReceipt(null), completes);
      await expectLater(service.deleteReceipt(''), completes);
      await expectLater(service.deleteReceipt('${tempDir.path}/does_not_exist.jpg'), completes);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/import/mmbak_import_service.dart';
import 'package:financial_recording/data/models/app_settings_model/app_settings_model.dart';
import 'package:financial_recording/data/services/pin_lock_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

import 'fixtures/make_mmbak.dart';

void main() {
  group('Impor .mmbak dari isi berkas (jalur web)', () {
    test('bytes tanpa path terbaca dan terpetakan', () async {
      final preview = await MmbakImportService().analyze(bytes: makeMmbakBytes());
      expect(preview.accounts.map((a) => a.name), containsAll(['Dompet', 'Bank']));
      expect(preview.transactions, hasLength(2));
      expect(preview.transactions.map((t) => t.amount), containsAll([25000, 1000000]));
    });
  });

  group('PIN 4–6 digit', () {
    setUp(() async {
      Hive.init('./.dart_tool/hive_test_pin');
      if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(TxTypeAdapter());
      if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(AppSettingsModelAdapter());
      final box = await Hive.openBox<AppSettingsModel>(AppBoxes.settings);
      await box.clear();
    });
    tearDown(() async => Hive.close());

    test('PIN 6 digit: panjang tersimpan dan hanya 6 digit penuh yang cocok', () async {
      final pin = PinLockService();
      await pin.setPin('123456');
      expect(pin.pinLength, 6);
      expect(pin.verify('1234'), isFalse);
      expect(pin.verify('123456'), isTrue);
    });

    test('PIN lama (tanpa panjang) tetap bisa diverifikasi', () async {
      final pin = PinLockService();
      await pin.setPin('987654');
      final box = Hive.box<AppSettingsModel>(AppBoxes.settings);
      final s = box.values.first;
      final parts = s.pinHash!.split(':');
      s.pinHash = '${parts[0]}:${parts[1]}';
      await s.save();
      expect(pin.pinLength, isNull);
      expect(pin.verify('987654'), isTrue);
    });
  });
}

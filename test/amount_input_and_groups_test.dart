import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/repositories/account_group_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';
import 'package:financial_recording/shared/widget/form/amount_field.dart';
import 'package:financial_recording/util/thousands_formatter/thousands_formatter.dart';

TextEditingValue _v(String text, [int? caret]) =>
    TextEditingValue(text: text, selection: TextSelection.collapsed(offset: caret ?? text.length));

void main() {
  group('Format nominal saat mengetik', () {
    final f = ThousandsFormatter();

    test('mengelompokkan ribuan dengan titik', () {
      final r = f.formatEditUpdate(_v('125.000'), _v('125.0000'));
      expect(r.text, '1.250.000');
      expect(r.selection.baseOffset, r.text.length);
    });

    test('kursor tetap di tempat saat menyisip angka di tengah', () {
      // "1.250.000" → ketik "9" setelah "1.2" → "1.2950.000"
      final r = f.formatEditUpdate(_v('1.250.000', 3), _v('1.2950.000', 4));
      expect(r.text, '12.950.000');
      // Kursor tetap tepat setelah angka "9" yang baru diketik.
      expect(r.text.substring(0, r.selection.baseOffset), '12.9');
    });

    test('backspace pada titik menghapus angka sebelumnya', () {
      // Kursor setelah titik di "1.250" lalu backspace.
      final r = f.formatEditUpdate(_v('1.250', 2), _v('1250', 1));
      expect(r.text, '250');
    });

    test('nol di depan dibuang, angka negatif bila diizinkan', () {
      expect(f.formatEditUpdate(_v(''), _v('007')).text, '7');
      final neg = ThousandsFormatter(allowNegative: true);
      expect(neg.formatEditUpdate(_v(''), _v('-1500000')).text, '-1.500.000');
      expect(parseThousands('-1.500.000', allowNegative: true), -1500000);
      expect(parseThousands('Rp 25.000'), 25000);
      expect(formatThousands(-2500), '-2.500');
    });
  });

  group('Nominal dibaca ulang', () {
    test('ribu, juta, miliar', () {
      expect(amountInWords(999), '');
      expect(amountInWords(250000), '250 ribu');
      expect(amountInWords(1500000), '1,5 juta');
      expect(amountInWords(1250000), '1,25 juta');
      expect(amountInWords(2000000000), '2 miliar');
      expect(amountInWords(1234567), '≈ 1,23 juta');
      expect(amountInWords(-50000), 'minus 50 ribu');
    });
  });

  group('Kelompok akun bisa diedit', () {
    setUp(() async {
      Hive.init('./.dart_tool/hive_test_groups');
      if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(TxCategoryModelAdapter());
      final box = await Hive.openBox<TxCategoryModel>(AppBoxes.categories);
      await box.clear();
    });
    tearDown(() async => Hive.close());

    test('bawaan tampil tanpa baris tersimpan, ganti nama tersinkron sebagai kategori tipe 2', () async {
      final repo = AccountGroupRepository();
      expect(repo.all().length, AccountGroupType.values.length);
      expect(repo.of(AccountGroupType.bank.code).label, 'Bank');

      await repo.save(repo.of(AccountGroupType.bank.code).copyWith(label: 'Rekening', icon: '🏛️'));
      expect(repo.of(AccountGroupType.bank.code).label, 'Rekening');

      // Disimpan di kotak kategori, tapi tidak muncul sebagai kategori transaksi.
      final cats = TxCategoryRepository();
      expect(cats.byId('accgroup-${AccountGroupType.bank.code}')?.typeCode, TxCategoryModel.accountGroupType);
      expect(cats.roots(0), isEmpty);
      expect(cats.roots(1), isEmpty);

      await repo.resetBuiltIn(AccountGroupType.bank.code);
      expect(repo.of(AccountGroupType.bank.code).label, 'Bank');
    });

    test('kelompok buatan sendiri: dibuat, urutan terakhir, bisa dihapus', () async {
      final repo = AccountGroupRepository();
      final g = await repo.create(label: 'Emas', icon: '🥇');
      expect(g.builtIn, isFalse);
      expect(repo.all().last.code, g.code);
      expect(repo.of(g.code).label, 'Emas');

      await repo.delete(g.code);
      expect(repo.all().any((x) => x.code == g.code), isFalse);
      // Kode tak dikenal jatuh ke "Lainnya".
      expect(repo.of(g.code).code, AccountGroupType.other.code);
      // Kelompok bawaan tidak bisa dihapus.
      await repo.delete(AccountGroupType.cash.code);
      expect(repo.of(AccountGroupType.cash.code).code, AccountGroupType.cash.code);
    });

    test('urutan bisa diubah', () async {
      final repo = AccountGroupRepository();
      final codes = repo.all().map((g) => g.code).toList();
      await repo.reorder([codes[1], codes[0], ...codes.skip(2)]);
      expect(repo.all().first.code, codes[1]);
    });
  });
}

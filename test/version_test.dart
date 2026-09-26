import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/shared/widget/account_card_stack.dart';

void main() {
  test('versi di Pengaturan sama dengan pubspec.yaml', () {
    final line = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    final name = line.split(':').last.trim().split('+').first;
    expect(AppConfig.appVersion, name);
  });

  test('catatan versi punya entri untuk versi ini, teks Play ≤ 500 karakter', () {
    expect(File('CHANGELOG.md').readAsStringSync(), contains('## ${AppConfig.appVersion}'));
    final whatsNew = File('docs/play-store/whatsnew-id-ID.txt').readAsStringSync().trim();
    expect(whatsNew.length, lessThanOrEqualTo(500));
  });

  test('deskripsi Play dalam batas karakter (80 & 4000)', () {
    final short = File('docs/play-store/short-description-id-ID.txt').readAsStringSync().trim();
    final full = File('docs/play-store/description-id-ID.txt').readAsStringSync().trim();
    expect(short.length, lessThanOrEqualTo(80));
    expect(full.length, lessThanOrEqualTo(4000));
    // Fitur yang sudah dihapus tidak boleh diiklankan.
    expect(full.toLowerCase(), isNot(contains('mmbak')));
  });

  test('urutan kartu tersimpan: akun terhapus dibuang, akun baru di depan', () {
    expect(CardOrderPrefs.apply(['b', 'x', 'a'], ['a', 'b', 'c']), ['c', 'b', 'a']);
    expect(CardOrderPrefs.apply([], ['a', 'b']), ['a', 'b']);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:financial_recording/app/distribution.dart';
import 'package:financial_recording/presentation/donation/view/donation_view.dart';

void main() {
  test('donasi aktif di build biasa (web & APK GitHub)', () {
    expect(kDistributionChannel, isEmpty);
    expect(kDonationsEnabled, isTrue);
  });

  testWidgets('halaman donasi menampilkan QRIS dan cara donasi', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DonationView()));
    await tester.pumpAndSettle();
    expect(find.text('Dukung Pengembang'), findsOneWidget);
    expect(find.bySemanticsLabel('Kode QRIS donasi atas nama DEIRSYAD'), findsOneWidget);
    expect(find.text('Simpan gambar QRIS'), findsOneWidget);
    expect(find.textContaining('DEIRSYAD'), findsWidgets);
  });
}

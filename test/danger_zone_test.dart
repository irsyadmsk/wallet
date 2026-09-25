import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:financial_recording/presentation/settings/view/danger_zone.dart';

void main() {
  testWidgets('tombol hapus baru aktif setelah mengetik HAPUS', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await confirmTyped(
              context,
              title: 'Hapus akun permanen?',
              body: 'Tidak bisa dibatalkan.',
              action: 'Hapus akun',
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus akun permanen?'), findsOneWidget);

    FilledButton button() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Hapus akun'));
    expect(button().onPressed, isNull, reason: 'belum mengetik HAPUS');

    await tester.enterText(find.byType(TextField), 'hapu');
    await tester.pump();
    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'hapus');
    await tester.pump();
    expect(button().onPressed, isNotNull, reason: 'huruf kecil juga diterima');

    await tester.tap(find.widgetWithText(FilledButton, 'Hapus akun'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('batal mengembalikan false', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await confirmTyped(context, title: 'T', body: 'B', action: 'Hapus'),
            child: const Text('buka'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}

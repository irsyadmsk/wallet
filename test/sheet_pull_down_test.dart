import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';

/// Forms open in a bottom sheet whose content scrolls, so the sheet's own
/// drag only worked on its small handle. Pulling down from the top of the
/// form must close it too.
void main() {
  testWidgets('menarik form ke bawah dari posisi paling atas menutup sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showAdaptiveSheet<void>(
                context,
                builder: (_) => ListView(
                  children: [for (var i = 0; i < 40; i++) ListTile(title: Text('Baris $i'))],
                ),
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    expect(find.text('Baris 0'), findsOneWidget);

    // Scrolling the form up and back is just scrolling.
    await tester.drag(find.text('Baris 3'), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Baris 6'), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(find.text('Baris 0'), findsOneWidget);

    // Already at the top: a further pull closes the sheet.
    await tester.drag(find.text('Baris 2'), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(find.text('Baris 0'), findsNothing);
  });
}

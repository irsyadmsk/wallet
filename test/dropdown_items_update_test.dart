import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/shared/widget/form/dropdown/dropdown.dart';

/// Regression: switching a form from Pengeluaran to Pemasukan kept showing
/// the expense categories because the dropdown copied its items only once.
void main() {
  testWidgets('QDropdownField ikut daftar item baru saat induk berganti', (tester) async {
    var income = false;
    late StateSetter set;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          set = setState;
          return QDropdownField(
            label: 'Kategori',
            value: null,
            items: income
                ? const [
                    {'value': 'gaji', 'label': 'Gaji'},
                  ]
                : const [
                    {'value': 'makan', 'label': 'Makanan'},
                  ],
            onChanged: (_, _) {},
          );
        }),
      ),
    ));

    await tester.tap(find.text('Kategori'));
    await tester.pumpAndSettle();
    expect(find.text('Makanan'), findsWidgets);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    set(() => income = true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kategori'));
    await tester.pumpAndSettle();
    expect(find.text('Gaji'), findsWidgets);
    expect(find.text('Makanan'), findsNothing);
  });
}

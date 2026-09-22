import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/debt_model/debt_model.dart';
import 'package:financial_recording/data/repositories/debt_repository.dart';
import 'package:financial_recording/shared/theme/art_icon_theme.dart';
import 'package:financial_recording/shared/widget/art_icon.dart';

void _registerOnce<T>(int typeId, TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
}

Future<void> _openBoxes() async {
  Hive.init('./.dart_tool/hive_test_debts');
  _registerOnce(17, DebtLoanModelAdapter());
  await Hive.openBox<DebtLoanModel>(AppBoxes.debts);
}

void main() {
  setUpAll(() async {
    await _openBoxes();
  });

  setUp(() async {
    await Hive.box<DebtLoanModel>(AppBoxes.debts).clear();
  });

  group('DebtLoanModel calculations', () {
    test('calculates paid amount and progress correctly', () {
      final debt = DebtLoanModel(
        id: 'd1',
        isLoan: false,
        personName: 'Budi',
        totalAmount: 1000000,
        remainingAmount: 400000,
      );

      expect(debt.paidAmount, 600000);
      expect(debt.progress, 0.6);
      expect(debt.progressPercent, 60);
      expect(debt.isSettled, isFalse);
    });

    test('flags overdue correctly', () {
      final pastDue = DebtLoanModel(
        id: 'd2',
        isLoan: true,
        personName: 'Andi',
        totalAmount: 500000,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(pastDue.isOverdue, isTrue);

      final futureDue = DebtLoanModel(
        id: 'd3',
        isLoan: true,
        personName: 'Citra',
        totalAmount: 500000,
        dueDate: DateTime.now().add(const Duration(days: 5)),
      );
      expect(futureDue.isOverdue, isFalse);
    });
  });

  group('DebtRepository CRUD and payment', () {
    test('upsert, filter debts vs loans, and recordPayment', () async {
      final repo = DebtRepository();

      final debt = DebtLoanModel(
        id: 'd1',
        isLoan: false,
        personName: 'Rian',
        totalAmount: 500000,
      );
      final loan = DebtLoanModel(
        id: 'd2',
        isLoan: true,
        personName: 'Siti',
        totalAmount: 300000,
      );

      await repo.upsert(debt);
      await repo.upsert(loan);

      expect(repo.all().length, 2);
      expect(repo.debts().length, 1);
      expect(repo.loans().length, 1);
      expect(repo.active().length, 2);

      // Record partial payment
      await repo.recordPayment('d1', 200000);
      var fetched = repo.byId('d1');
      expect(fetched!.remainingAmount, 300000);
      expect(fetched.isSettled, isFalse);

      // Record full remaining payment
      await repo.recordPayment('d1', 300000);
      fetched = repo.byId('d1');
      expect(fetched!.remainingAmount, 0);
      expect(fetched.isSettled, isTrue);
      expect(repo.active().length, 1);
    });
  });

  group('ART+ Icon Theme and Widget', () {
    test('enum defines all 5 shapes with proper labels', () {
      expect(ArtShape.values.length, 5);
      expect(ArtShape.squircle.label, contains('Squircle'));
      expect(ArtShape.circle.label, contains('Circle'));
      expect(ArtShape.hexagon.label, contains('Hexagon'));
      expect(ArtShape.roundedSquare.label, contains('Rounded Box'));
      expect(ArtShape.stadium.label, contains('Stadium'));
    });

    testWidgets('ArtIcon renders in all shapes without exception', (tester) async {
      for (final shape in ArtShape.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ArtIcon(
                shapeOverride: shape,
                size: 48,
                icon: Icons.wallet_rounded,
                iconColor: Colors.teal,
                showAura: true,
              ),
            ),
          ),
        );
        expect(find.byType(ArtIcon), findsOneWidget);
      }
    });
  });
}

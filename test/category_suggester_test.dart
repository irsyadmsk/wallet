import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/services/category_suggester.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

var _n = 0;
TxModel t(String memo, String cat, {TxType type = TxType.expense}) =>
    TxModel(id: '${_n++}', type: type, amount: 1, accountId: 'a', categoryId: cat, date: DateTime(2026), memo: memo);

void main() {
  final history = [
    t('Kopi Kenangan', 'food'),
    t('Kopi Kenangan', 'food'),
    t('kopi susu', 'food'),
    t('Bensin Pertamina', 'transport'),
    t('Pertamina isi bensin', 'transport'),
    t('Gaji Sekolah', 'salary', type: TxType.income),
  ];

  test('exact memo match wins', () {
    expect(CategorySuggester.suggest('kopi kenangan', TxType.expense, history), 'food');
  });

  test('keywords vote when there is no exact match', () {
    expect(CategorySuggester.suggest('bensin motor', TxType.expense, history), 'transport');
    expect(CategorySuggester.suggest('kopi tuku', TxType.expense, history), 'food');
  });

  test('no guess when history is thin, ambiguous, or the type differs', () {
    expect(CategorySuggester.suggest('sekolah', TxType.expense, history), isNull);
    expect(CategorySuggester.suggest('xy', TxType.expense, history), isNull);
    expect(CategorySuggester.suggest('bensin', TxType.transfer, history), isNull);
  });
}

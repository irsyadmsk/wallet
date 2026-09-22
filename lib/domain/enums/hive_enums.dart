import 'package:hive/hive.dart';

part 'hive_enums.g.dart';

@HiveType(typeId: 12)
enum TxType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  transfer,
}

@HiveType(typeId: 13)
enum BudgetPeriod {
  @HiveField(0)
  monthly,
}

@HiveType(typeId: 14)
enum RecurrenceFreq {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly,
}

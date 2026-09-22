import 'package:financial_recording/domain/enums/hive_enums.dart';

enum TxSort { dateDesc, dateAsc, amountDesc, amountAsc }

class TxQuery {
  DateTime? from;
  DateTime? to;
  Set<TxType>? types;
  Set<String>? accountIds;
  Set<String>? categoryIds;
  Set<String>? tagIds;
  int? minAmount;
  int? maxAmount;
  String? search;
  int? limit;
  TxSort sort;

  TxQuery({
    this.from,
    this.to,
    this.types,
    this.accountIds,
    this.categoryIds,
    this.tagIds,
    this.minAmount,
    this.maxAmount,
    this.search,
    this.limit,
    this.sort = TxSort.dateDesc,
  });
}

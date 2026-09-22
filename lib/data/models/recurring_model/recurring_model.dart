import 'package:hive/hive.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

part 'recurring_model.g.dart';

@HiveType(typeId: 10)
class RecurringRuleModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  TxType type;

  @HiveField(2)
  int amount;

  @HiveField(3)
  String accountId;

  @HiveField(4)
  String? toAccountId;

  @HiveField(5)
  String? categoryId;

  @HiveField(6)
  String? memo;

  @HiveField(7)
  RecurrenceFreq freq;

  @HiveField(8)
  int interval;

  @HiveField(9)
  DateTime startDate;

  @HiveField(10)
  DateTime? endDate;

  @HiveField(11)
  DateTime nextRunDate;

  @HiveField(12)
  DateTime? lastPostedDate;

  @HiveField(13)
  bool autoPost;

  @HiveField(14)
  bool isActive;

  @HiveField(15)
  String? externalId;

  RecurringRuleModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.memo,
    this.freq = RecurrenceFreq.monthly,
    this.interval = 1,
    required this.startDate,
    this.endDate,
    DateTime? nextRunDate,
    this.lastPostedDate,
    this.autoPost = true,
    this.isActive = true,
    this.externalId,
  }) : nextRunDate = nextRunDate ?? startDate;

  DateTime computeNextRun(DateTime from) {
    switch (freq) {
      case RecurrenceFreq.daily:
        return DateTime(from.year, from.month, from.day + interval, from.hour, from.minute);
      case RecurrenceFreq.weekly:
        return DateTime(from.year, from.month, from.day + 7 * interval, from.hour, from.minute);
      case RecurrenceFreq.monthly:
        final targetMonthIndex = from.month - 1 + interval;
        final year = from.year + targetMonthIndex ~/ 12;
        final month = targetMonthIndex % 12 + 1;
        final lastDay = DateTime(year, month + 1, 0).day;
        final day = from.day > lastDay ? lastDay : from.day;
        return DateTime(year, month, day, from.hour, from.minute);
      case RecurrenceFreq.yearly:
        return DateTime(from.year + interval, from.month, from.day, from.hour, from.minute);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'categoryId': categoryId,
        'memo': memo,
        'freq': freq.name,
        'interval': interval,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'nextRunDate': nextRunDate.toIso8601String(),
        'lastPostedDate': lastPostedDate?.toIso8601String(),
        'autoPost': autoPost,
        'isActive': isActive,
        'externalId': externalId,
      };

  factory RecurringRuleModel.fromJson(Map<String, dynamic> json) => RecurringRuleModel(
        id: json['id'] as String,
        type: TxType.values.firstWhere((t) => t.name == json['type'], orElse: () => TxType.expense),
        amount: int.tryParse(json['amount'].toString()) ?? 0,
        accountId: json['accountId']?.toString() ?? '',
        toAccountId: json['toAccountId'] as String?,
        categoryId: json['categoryId'] as String?,
        memo: json['memo'] as String?,
        freq: RecurrenceFreq.values.firstWhere((f) => f.name == json['freq'], orElse: () => RecurrenceFreq.monthly),
        interval: int.tryParse(json['interval'].toString()) ?? 1,
        startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
        endDate: json['endDate'] == null ? null : DateTime.tryParse(json['endDate'].toString()),
        nextRunDate: DateTime.tryParse(json['nextRunDate']?.toString() ?? '') ?? DateTime.now(),
        lastPostedDate: json['lastPostedDate'] == null ? null : DateTime.tryParse(json['lastPostedDate'].toString()),
        autoPost: json['autoPost'] as bool? ?? true,
        isActive: json['isActive'] as bool? ?? true,
        externalId: json['externalId'] as String?,
      );
}

import 'package:hive/hive.dart';

part 'memo_model.g.dart';

/// A free-form daily note, independent of any transaction — mirrors the
/// "Memo" tab in Money Manager (e.g. "gajian tanggal segini", reminders).
@HiveType(typeId: 18)
class MemoModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String title;

  @HiveField(3)
  String body;

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  bool pinned;

  @HiveField(6)
  DateTime updatedAt;

  MemoModel({
    required this.id,
    required this.date,
    this.title = '',
    this.body = '',
    this.colorValue = 0xFFF6C76B,
    this.pinned = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'body': body,
        'colorValue': colorValue,
        'pinned': pinned,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MemoModel.fromJson(Map<String, dynamic> json) => MemoModel(
        id: json['id'] as String,
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        colorValue: int.tryParse(json['colorValue'].toString()) ?? 0xFFF6C76B,
        pinned: json['pinned'] as bool? ?? false,
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

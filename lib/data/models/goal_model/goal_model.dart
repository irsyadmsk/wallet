import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 15)
class FinancialGoalModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  int targetAmount;

  @HiveField(3)
  int currentAmount;

  @HiveField(4)
  DateTime? targetDate;

  @HiveField(5)
  int colorValue;

  @HiveField(6)
  String iconName;

  @HiveField(7)
  bool isCompleted;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  String? notes;

  FinancialGoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.targetDate,
    this.colorValue = 0xFF0D9488,
    this.iconName = 'savings',
    this.isCompleted = false,
    DateTime? createdAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress => targetAmount <= 0 ? 1.0 : (currentAmount / targetAmount).clamp(0.0, 1.0);
  int get remainingAmount => (targetAmount - currentAmount).clamp(0, targetAmount);
  int get progressPercent => (progress * 100).round();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate?.toIso8601String(),
        'colorValue': colorValue,
        'iconName': iconName,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
      };

  factory FinancialGoalModel.fromJson(Map<String, dynamic> json) => FinancialGoalModel(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        targetAmount: (json['targetAmount'] as num?)?.toInt() ?? 0,
        currentAmount: (json['currentAmount'] as num?)?.toInt() ?? 0,
        targetDate: json['targetDate'] != null ? DateTime.tryParse(json['targetDate'].toString()) : null,
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF0D9488,
        iconName: json['iconName'] as String? ?? 'savings',
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
        notes: json['notes'] as String?,
      );
}

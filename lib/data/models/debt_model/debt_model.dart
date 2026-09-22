import 'package:hive/hive.dart';

part 'debt_model.g.dart';

@HiveType(typeId: 17)
class DebtLoanModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  bool isLoan; // true = Piutang (saya meminjamkan), false = Utang (saya berutang)

  @HiveField(2)
  String personName;

  @HiveField(3)
  int totalAmount;

  @HiveField(4)
  int remainingAmount;

  @HiveField(5)
  DateTime? dueDate;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  bool isSettled;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  int colorValue;

  DebtLoanModel({
    required this.id,
    required this.isLoan,
    required this.personName,
    required this.totalAmount,
    int? remainingAmount,
    this.dueDate,
    this.notes,
    this.isSettled = false,
    DateTime? createdAt,
    this.colorValue = 0xFF0D9488,
  })  : remainingAmount = remainingAmount ?? totalAmount,
        createdAt = createdAt ?? DateTime.now();

  int get paidAmount => (totalAmount - remainingAmount).clamp(0, totalAmount);
  double get progress => totalAmount <= 0 ? 1.0 : (paidAmount / totalAmount).clamp(0.0, 1.0);
  int get progressPercent => (progress * 100).round();
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && !isSettled;

  Map<String, dynamic> toJson() => {
        'id': id,
        'isLoan': isLoan,
        'personName': personName,
        'totalAmount': totalAmount,
        'remainingAmount': remainingAmount,
        'dueDate': dueDate?.toIso8601String(),
        'notes': notes,
        'isSettled': isSettled,
        'createdAt': createdAt.toIso8601String(),
        'colorValue': colorValue,
      };

  factory DebtLoanModel.fromJson(Map<String, dynamic> json) => DebtLoanModel(
        id: json['id'] as String,
        isLoan: json['isLoan'] as bool? ?? false,
        personName: json['personName']?.toString() ?? '',
        totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
        remainingAmount: (json['remainingAmount'] as num?)?.toInt(),
        dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
        notes: json['notes'] as String?,
        isSettled: json['isSettled'] as bool? ?? false,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF0D9488,
      );
}

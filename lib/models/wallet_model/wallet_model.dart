import 'dart:ui';

import 'package:hive/hive.dart';

part 'wallet_model.g.dart';

@HiveType(typeId: 2)
class WalletModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int balance;

  @HiveField(2)
  int? todayExpense;

  @HiveField(3)
  List<int> gradient;

  @HiveField(4)
  String iconPath;

  WalletModel({
    required this.name,
    required this.iconPath,
    required this.balance,
    required this.gradient,
    this.todayExpense,
  });

  List<Color> get gradientColors => gradient.map((c) => Color(c)).toList();
  set gradientColors(List<Color> colors) =>
      gradient = colors.map((c) => c.value).toList();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'iconPath': iconPath,
      'balance': balance,
      'gradient': gradient,
      'todayExpense': todayExpense,
    };
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    List<int> parsedGradient = [0xFF4F46E5, 0xFF6366F1];
    if (json['gradient'] is List) {
      parsedGradient = (json['gradient'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0xFF4F46E5)
          .toList();
    }

    return WalletModel(
      name: json['name']?.toString() ?? '',
      iconPath: json['iconPath']?.toString() ?? 'assets/icon_pack/bank_logo/bi.png',
      balance: int.tryParse(json['balance']?.toString() ?? '0') ?? 0,
      gradient: parsedGradient,
      todayExpense: json['todayExpense'] != null
          ? int.tryParse(json['todayExpense'].toString())
          : null,
    );
  }
}

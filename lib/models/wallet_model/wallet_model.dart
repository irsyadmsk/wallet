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
}

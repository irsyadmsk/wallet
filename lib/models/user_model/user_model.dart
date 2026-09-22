import 'dart:ui';

import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  String? fullName;

  @HiveField(1)
  String email;

  @HiveField(2)
  String? username;

  @HiveField(3)
  String password;

  UserModel({
    required this.email,
    required this.password,
    this.username,
    this.fullName,
  });
}

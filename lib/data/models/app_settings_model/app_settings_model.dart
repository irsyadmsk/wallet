import 'package:hive/hive.dart';

part 'app_settings_model.g.dart';

@HiveType(typeId: 11)
class AppSettingsModel extends HiveObject {
  @HiveField(0)
  int themeModeIndex; // 0 system, 1 light, 2 dark

  @HiveField(1)
  int seedColorValue;

  @HiveField(2)
  String currencyCode;

  @HiveField(3)
  bool hideBalances;

  @HiveField(4)
  bool onboardingDone;

  @HiveField(5)
  String? defaultAccountId;

  @HiveField(6)
  bool legacyDataPurged;

  @HiveField(7)
  DateTime? lastRecurringRunAt;

  @HiveField(8)
  int iconShapeIndex; // 0: squircle, 1: circle, 2: hexagon, 3: roundedSquare, 4: stadium

  AppSettingsModel({
    this.themeModeIndex = 0,
    this.seedColorValue = 0xFF0D9488,
    this.currencyCode = 'IDR',
    this.hideBalances = false,
    this.onboardingDone = false,
    this.defaultAccountId,
    this.legacyDataPurged = false,
    this.lastRecurringRunAt,
    this.iconShapeIndex = 0,
  });
}

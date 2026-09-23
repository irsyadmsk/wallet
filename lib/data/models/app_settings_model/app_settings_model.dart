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

  // `defaultValue:` matters on every non-nullable field added after first
  // release: without it, Hive casts a missing key straight to the type
  // (`null as bool`) and throws for every browser/device whose stored
  // record predates the field, instead of falling back — which is exactly
  // what broke the app for every returning visitor when pinEnabled shipped
  // with a bare `as bool`.
  @HiveField(8, defaultValue: 0)
  int iconShapeIndex; // 0: squircle, 1: circle, 2: hexagon, 3: roundedSquare, 4: stadium

  /// Salted hash of the app-lock PIN — see [PinLockService]. Never the raw
  /// PIN itself, and this is device-local UI security, not synced.
  @HiveField(9)
  String? pinHash;

  @HiveField(10, defaultValue: false)
  bool pinEnabled;

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
    this.pinHash,
    this.pinEnabled = false,
  });
}

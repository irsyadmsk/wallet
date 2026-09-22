import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/app_settings_model/app_settings_model.dart';

const _kSettingsKey = 'app';

class SettingsRepository {
  Box<AppSettingsModel> get _box => Hive.box<AppSettingsModel>(AppBoxes.settings);

  AppSettingsModel get current {
    var s = _box.get(_kSettingsKey);
    if (s == null) {
      s = AppSettingsModel();
      _box.put(_kSettingsKey, s);
    }
    return s;
  }

  Future<void> save(AppSettingsModel settings) => _box.put(_kSettingsKey, settings);
}

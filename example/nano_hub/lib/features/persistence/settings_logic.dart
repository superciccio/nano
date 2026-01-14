import 'package:nano/nano.dart';

class SettingsLogic extends NanoLogic {
  /// Automated persistence for the theme mode.
  late final isDarkMode = PersistAtom<bool>(
    true,
    key: 'is_dark_mode',
    label: 'settings_dark_mode',
  );

  /// Automated persistence for the update frequency.
  late final refreshInterval = PersistAtom<double>(
    1.0,
    key: 'refresh_interval',
    label: 'settings_refresh_interval',
  );

  void toggleTheme() => isDarkMode.value = !isDarkMode.value;

  void setRefreshInterval(double value) => refreshInterval.value = value;

  @override
  void onInit(void params) {
    print("?? SETTINGS: onInit");
  }

  @override
  void onReady() {
    print("?? SETTINGS: onReady");
    status.value = NanoStatus.success;
  }
}

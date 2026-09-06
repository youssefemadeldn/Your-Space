import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Non-secret app-level flags backed by `SharedPreferences` — the counterpart to
/// [SecureStorageHelper] (which is for actual session/credential data). Generic
/// enough for future flags of the same kind, not onboarding-only.
@lazySingleton
class AppPreferencesHelper {
  final SharedPreferences _preferences;

  AppPreferencesHelper(this._preferences);

  bool hasSeenOnboarding() => _preferences.getBool(AppConstants.kHasSeenOnboardingKey) ?? false;

  Future<void> setSeenOnboarding() =>
      _preferences.setBool(AppConstants.kHasSeenOnboardingKey, true);
}

import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resolves the app's current language code with no `BuildContext` — network
/// layer classes (interceptors, `DioFactory`) can't reach `easy_localization`'s
/// `context.locale`. Reads the same `'locale'` key `easy_localization` itself
/// writes once a language switcher exists and is used; falls back to matching
/// the device locale against the app's supported locales otherwise.
@lazySingleton
class LocaleHelper {
  final SharedPreferences _prefs;

  LocaleHelper(this._prefs);

  static const _supportedLanguageCodes = ['en', 'ar'];
  static const _defaultLanguageCode = 'en';

  String currentLanguageCode() {
    final saved = _prefs.getString('locale');
    if (saved != null && _supportedLanguageCodes.contains(saved)) {
      return saved;
    }

    final deviceLanguageCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return _supportedLanguageCodes.contains(deviceLanguageCode) ? deviceLanguageCode : _defaultLanguageCode;
  }
}

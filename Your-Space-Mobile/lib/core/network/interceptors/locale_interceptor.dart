import 'package:dio/dio.dart';

import '../../helpers/locale_helper.dart';

/// Sets `Accept-Language` on every request so the backend's
/// `RequestLocalizationOptions` resolves bilingual fields (Group/Event name,
/// etc.) in the app's actual current language instead of always defaulting
/// to English.
class LocaleInterceptor extends Interceptor {
  final LocaleHelper _localeHelper;

  LocaleInterceptor(this._localeHelper);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _localeHelper.currentLanguageCode();
    handler.next(options);
  }
}

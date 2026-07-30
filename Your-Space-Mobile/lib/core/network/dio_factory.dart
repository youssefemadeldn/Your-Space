import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import '../helpers/locale_helper.dart';
import '../storage/secure_storage_helper.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/locale_interceptor.dart';

@lazySingleton
class DioFactory {
  final SecureStorageHelper _secureStorage;
  final GoRouter _router;
  final LocaleHelper _localeHelper;

  DioFactory(this._secureStorage, this._router, this._localeHelper);

  Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
      ),
    );

    // Logger must run before AuthInterceptor — otherwise it logs the
    // Authorization header AuthInterceptor just attached.
    if (kDebugMode) {
      dio.interceptors.add(PrettyDioLogger(requestHeader: true, requestBody: true));
    }
    dio.interceptors.add(LocaleInterceptor(_localeHelper));
    dio.interceptors.add(AuthInterceptor(_secureStorage, _router));

    return dio;
  }
}

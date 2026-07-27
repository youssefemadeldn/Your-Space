import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_helper.dart';
import 'interceptors/auth_interceptor.dart';

@lazySingleton
class DioFactory {
  final SecureStorageHelper _secureStorage;
  final GoRouter _router;

  DioFactory(this._secureStorage, this._router);

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
    dio.interceptors.add(AuthInterceptor(_secureStorage, _router));

    return dio;
  }
}

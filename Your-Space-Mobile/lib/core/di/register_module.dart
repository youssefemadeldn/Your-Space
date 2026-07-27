import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/dio_factory.dart';
import '../router/app_router.dart';

@module
abstract class RegisterModule {
  // v10+ auto-migrates to custom ciphers — no AndroidOptions needed; that API
  // is deprecated and removed in v11.
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @singleton
  GlobalKey<NavigatorState> get navigatorKey => GlobalKey<NavigatorState>();

  @singleton
  GoRouter router(GlobalKey<NavigatorState> navigatorKey) => AppRouter.router(navigatorKey);

  @singleton
  Dio dio(DioFactory dioFactory) => dioFactory.create();

  @preResolve
  @singleton
  Future<SharedPreferences> get sharedPreferences => SharedPreferences.getInstance();
}

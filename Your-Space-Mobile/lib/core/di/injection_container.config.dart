// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter/material.dart' as _i409;
import 'package:flutter/widgets.dart' as _i718;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:go_router/go_router.dart' as _i583;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:your_space_mobile/core/di/register_module.dart' as _i876;
import 'package:your_space_mobile/core/helpers/dialog_helper.dart' as _i733;
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart' as _i967;
import 'package:your_space_mobile/core/network/api_manager.dart' as _i531;
import 'package:your_space_mobile/core/network/connectivity_helper.dart' as _i0;
import 'package:your_space_mobile/core/network/dio_factory.dart' as _i927;
import 'package:your_space_mobile/core/storage/secure_storage_helper.dart'
    as _i134;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.singleton<_i718.GlobalKey<_i718.NavigatorState>>(
      () => registerModule.navigatorKey,
    );
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i0.ConnectivityHelper>(() => _i0.ConnectivityHelper());
    gh.lazySingleton<_i134.SecureStorageHelper>(
      () => _i134.SecureStorageHelper(gh<_i558.FlutterSecureStorage>()),
    );
    gh.singleton<_i583.GoRouter>(
      () => registerModule.router(gh<_i718.GlobalKey<_i718.NavigatorState>>()),
    );
    gh.lazySingleton<_i733.DialogHelper>(
      () => _i733.DialogHelper(gh<_i409.GlobalKey<_i409.NavigatorState>>()),
    );
    gh.lazySingleton<_i967.SnackBarHelper>(
      () => _i967.SnackBarHelper(gh<_i409.GlobalKey<_i409.NavigatorState>>()),
    );
    gh.lazySingleton<_i927.DioFactory>(
      () => _i927.DioFactory(
        gh<_i134.SecureStorageHelper>(),
        gh<_i583.GoRouter>(),
      ),
    );
    gh.singleton<_i361.Dio>(() => registerModule.dio(gh<_i927.DioFactory>()));
    gh.lazySingleton<_i531.ApiManager>(() => _i531.ApiManager(gh<_i361.Dio>()));
    return this;
  }
}

class _$RegisterModule extends _i876.RegisterModule {}

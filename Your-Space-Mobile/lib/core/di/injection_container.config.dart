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
import 'package:your_space_mobile/features/auth/data/datasources/auth_remote_data_source_impl.dart'
    as _i1073;
import 'package:your_space_mobile/features/auth/data/repositories/auth_repository_impl.dart'
    as _i722;
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart'
    as _i680;
import 'package:your_space_mobile/features/auth/presentation/cubit/change_password_cubit/change_password_cubit.dart'
    as _i1019;
import 'package:your_space_mobile/features/auth/presentation/cubit/confirm_email_cubit/confirm_email_cubit.dart'
    as _i723;
import 'package:your_space_mobile/features/auth/presentation/cubit/forgot_password_cubit/forgot_password_cubit.dart'
    as _i613;
import 'package:your_space_mobile/features/auth/presentation/cubit/login_cubit/login_cubit.dart'
    as _i968;
import 'package:your_space_mobile/features/auth/presentation/cubit/register_cubit/register_cubit.dart'
    as _i44;
import 'package:your_space_mobile/features/auth/presentation/cubit/reset_password_cubit/reset_password_cubit.dart'
    as _i115;

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
    gh.lazySingleton<_i1073.AuthRemoteDataSourceImpl>(
      () => _i1073.AuthRemoteDataSourceImpl(gh<_i531.ApiManager>()),
    );
    gh.lazySingleton<_i680.AuthRepository>(
      () => _i722.AuthRepositoryImpl(
        gh<_i1073.AuthRemoteDataSourceImpl>(),
        gh<_i134.SecureStorageHelper>(),
      ),
    );
    gh.factory<_i1019.ChangePasswordCubit>(
      () => _i1019.ChangePasswordCubit(gh<_i680.AuthRepository>()),
    );
    gh.factory<_i723.ConfirmEmailCubit>(
      () => _i723.ConfirmEmailCubit(gh<_i680.AuthRepository>()),
    );
    gh.factory<_i613.ForgotPasswordCubit>(
      () => _i613.ForgotPasswordCubit(gh<_i680.AuthRepository>()),
    );
    gh.factory<_i968.LoginCubit>(
      () => _i968.LoginCubit(gh<_i680.AuthRepository>()),
    );
    gh.factory<_i44.RegisterCubit>(
      () => _i44.RegisterCubit(gh<_i680.AuthRepository>()),
    );
    gh.factory<_i115.ResetPasswordCubit>(
      () => _i115.ResetPasswordCubit(gh<_i680.AuthRepository>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i876.RegisterModule {}

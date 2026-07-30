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
import 'package:your_space_mobile/core/helpers/locale_helper.dart' as _i559;
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
import 'package:your_space_mobile/features/events/data/datasources/event_guest_remote_data_source_impl.dart'
    as _i320;
import 'package:your_space_mobile/features/events/data/datasources/event_remote_data_source_impl.dart'
    as _i557;
import 'package:your_space_mobile/features/events/data/repositories/event_guest_repository_impl.dart'
    as _i1063;
import 'package:your_space_mobile/features/events/data/repositories/event_repository_impl.dart'
    as _i155;
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart'
    as _i235;
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart'
    as _i219;
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_action_cubit/add_guests_action_cubit.dart'
    as _i426;
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_list_cubit/add_guests_list_cubit.dart'
    as _i895;
import 'package:your_space_mobile/features/events/presentation/cubit/event_details_cubit/event_details_cubit.dart'
    as _i391;
import 'package:your_space_mobile/features/events/presentation/cubit/event_form_cubit/event_form_cubit.dart'
    as _i755;
import 'package:your_space_mobile/features/events/presentation/cubit/event_guest_action_cubit/event_guest_action_cubit.dart'
    as _i410;
import 'package:your_space_mobile/features/events/presentation/cubit/event_guests_list_cubit/event_guests_list_cubit.dart'
    as _i889;
import 'package:your_space_mobile/features/events/presentation/cubit/events_list_cubit/events_list_cubit.dart'
    as _i890;
import 'package:your_space_mobile/features/events/presentation/cubit/reciprocity_suggestions_cubit/reciprocity_suggestions_cubit.dart'
    as _i147;
import 'package:your_space_mobile/features/groups/data/datasources/group_remote_data_source_impl.dart'
    as _i190;
import 'package:your_space_mobile/features/groups/data/repositories/group_repository_impl.dart'
    as _i612;
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart'
    as _i994;
import 'package:your_space_mobile/features/groups/presentation/cubit/group_action_cubit/group_action_cubit.dart'
    as _i965;
import 'package:your_space_mobile/features/groups/presentation/cubit/groups_list_cubit/groups_list_cubit.dart'
    as _i771;
import 'package:your_space_mobile/features/home/presentation/cubit/home_stats_cubit/home_stats_cubit.dart'
    as _i136;
import 'package:your_space_mobile/features/people/data/datasources/person_remote_data_source_impl.dart'
    as _i293;
import 'package:your_space_mobile/features/people/data/repositories/person_repository_impl.dart'
    as _i504;
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart'
    as _i571;
import 'package:your_space_mobile/features/people/presentation/cubit/add_occasion_cubit/add_occasion_cubit.dart'
    as _i641;
import 'package:your_space_mobile/features/people/presentation/cubit/people_list_cubit/people_list_cubit.dart'
    as _i512;
import 'package:your_space_mobile/features/people/presentation/cubit/person_details_cubit/person_details_cubit.dart'
    as _i930;
import 'package:your_space_mobile/features/people/presentation/cubit/person_form_cubit/person_form_cubit.dart'
    as _i228;

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
    gh.lazySingleton<_i559.LocaleHelper>(
      () => _i559.LocaleHelper(gh<_i460.SharedPreferences>()),
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
        gh<_i559.LocaleHelper>(),
      ),
    );
    gh.singleton<_i361.Dio>(() => registerModule.dio(gh<_i927.DioFactory>()));
    gh.lazySingleton<_i531.ApiManager>(() => _i531.ApiManager(gh<_i361.Dio>()));
    gh.lazySingleton<_i1073.AuthRemoteDataSourceImpl>(
      () => _i1073.AuthRemoteDataSourceImpl(gh<_i531.ApiManager>()),
    );
    gh.lazySingleton<_i320.EventGuestRemoteDataSourceImpl>(
      () => _i320.EventGuestRemoteDataSourceImpl(gh<_i531.ApiManager>()),
    );
    gh.lazySingleton<_i557.EventRemoteDataSourceImpl>(
      () => _i557.EventRemoteDataSourceImpl(gh<_i531.ApiManager>()),
    );
    gh.lazySingleton<_i190.GroupRemoteDataSourceImpl>(
      () => _i190.GroupRemoteDataSourceImpl(gh<_i531.ApiManager>()),
    );
    gh.lazySingleton<_i293.PersonRemoteDataSourceImpl>(
      () => _i293.PersonRemoteDataSourceImpl(gh<_i531.ApiManager>()),
    );
    gh.lazySingleton<_i235.EventGuestRepository>(
      () => _i1063.EventGuestRepositoryImpl(
        gh<_i320.EventGuestRemoteDataSourceImpl>(),
      ),
    );
    gh.lazySingleton<_i994.GroupRepository>(
      () => _i612.GroupRepositoryImpl(gh<_i190.GroupRemoteDataSourceImpl>()),
    );
    gh.lazySingleton<_i571.PersonRepository>(
      () => _i504.PersonRepositoryImpl(gh<_i293.PersonRemoteDataSourceImpl>()),
    );
    gh.factory<_i889.EventGuestsListCubit>(
      () => _i889.EventGuestsListCubit(
        gh<_i235.EventGuestRepository>(),
        gh<_i994.GroupRepository>(),
      ),
    );
    gh.factory<_i147.ReciprocitySuggestionsCubit>(
      () => _i147.ReciprocitySuggestionsCubit(
        gh<_i235.EventGuestRepository>(),
        gh<_i994.GroupRepository>(),
      ),
    );
    gh.lazySingleton<_i680.AuthRepository>(
      () => _i722.AuthRepositoryImpl(
        gh<_i1073.AuthRemoteDataSourceImpl>(),
        gh<_i134.SecureStorageHelper>(),
      ),
    );
    gh.lazySingleton<_i219.EventRepository>(
      () => _i155.EventRepositoryImpl(gh<_i557.EventRemoteDataSourceImpl>()),
    );
    gh.factory<_i755.EventFormCubit>(
      () => _i755.EventFormCubit(gh<_i219.EventRepository>()),
    );
    gh.factory<_i890.EventsListCubit>(
      () => _i890.EventsListCubit(gh<_i219.EventRepository>()),
    );
    gh.factory<_i136.HomeStatsCubit>(
      () => _i136.HomeStatsCubit(
        gh<_i994.GroupRepository>(),
        gh<_i571.PersonRepository>(),
        gh<_i219.EventRepository>(),
      ),
    );
    gh.factory<_i512.PeopleListCubit>(
      () => _i512.PeopleListCubit(
        gh<_i571.PersonRepository>(),
        gh<_i994.GroupRepository>(),
      ),
    );
    gh.factory<_i228.PersonFormCubit>(
      () => _i228.PersonFormCubit(
        gh<_i571.PersonRepository>(),
        gh<_i994.GroupRepository>(),
      ),
    );
    gh.factory<_i426.AddGuestsActionCubit>(
      () => _i426.AddGuestsActionCubit(gh<_i235.EventGuestRepository>()),
    );
    gh.factory<_i410.EventGuestActionCubit>(
      () => _i410.EventGuestActionCubit(gh<_i235.EventGuestRepository>()),
    );
    gh.factory<_i895.AddGuestsListCubit>(
      () => _i895.AddGuestsListCubit(
        gh<_i571.PersonRepository>(),
        gh<_i235.EventGuestRepository>(),
      ),
    );
    gh.factory<_i965.GroupActionCubit>(
      () => _i965.GroupActionCubit(gh<_i994.GroupRepository>()),
    );
    gh.factory<_i771.GroupsListCubit>(
      () => _i771.GroupsListCubit(gh<_i994.GroupRepository>()),
    );
    gh.factory<_i641.AddOccasionCubit>(
      () => _i641.AddOccasionCubit(gh<_i571.PersonRepository>()),
    );
    gh.factory<_i930.PersonDetailsCubit>(
      () => _i930.PersonDetailsCubit(gh<_i571.PersonRepository>()),
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
    gh.factory<_i391.EventDetailsCubit>(
      () => _i391.EventDetailsCubit(
        gh<_i219.EventRepository>(),
        gh<_i235.EventGuestRepository>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i876.RegisterModule {}

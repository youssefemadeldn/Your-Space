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
import 'package:your_space_mobile/core/database/app_database.dart' as _i935;
import 'package:your_space_mobile/core/di/register_module.dart' as _i876;
import 'package:your_space_mobile/core/events/data_refresh_bus.dart' as _i215;
import 'package:your_space_mobile/core/helpers/dialog_helper.dart' as _i733;
import 'package:your_space_mobile/core/helpers/locale_helper.dart' as _i559;
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart' as _i967;
import 'package:your_space_mobile/core/network/api_manager.dart' as _i531;
import 'package:your_space_mobile/core/network/connectivity_helper.dart' as _i0;
import 'package:your_space_mobile/core/network/dio_factory.dart' as _i927;
import 'package:your_space_mobile/core/storage/app_preferences_helper.dart'
    as _i782;
import 'package:your_space_mobile/core/storage/secure_storage_helper.dart'
    as _i134;
import 'package:your_space_mobile/core/sync/collection_puller.dart' as _i635;
import 'package:your_space_mobile/core/sync/outbox_replayer.dart' as _i222;
import 'package:your_space_mobile/core/sync/sync_service.dart' as _i477;
import 'package:your_space_mobile/features/auth/data/datasources/auth_remote_data_source_impl.dart'
    as _i1073;
import 'package:your_space_mobile/features/auth/data/repositories/auth_repository_impl.dart'
    as _i722;
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart'
    as _i680;
import 'package:your_space_mobile/features/auth/domain/use_cases/get_current_user_profile_use_case.dart'
    as _i84;
import 'package:your_space_mobile/features/auth/presentation/cubit/change_password_cubit/change_password_cubit.dart'
    as _i1019;
import 'package:your_space_mobile/features/auth/presentation/cubit/confirm_email_cubit/confirm_email_cubit.dart'
    as _i723;
import 'package:your_space_mobile/features/auth/presentation/cubit/delete_account_cubit/delete_account_cubit.dart'
    as _i516;
import 'package:your_space_mobile/features/auth/presentation/cubit/forgot_password_cubit/forgot_password_cubit.dart'
    as _i613;
import 'package:your_space_mobile/features/auth/presentation/cubit/login_cubit/login_cubit.dart'
    as _i968;
import 'package:your_space_mobile/features/auth/presentation/cubit/register_cubit/register_cubit.dart'
    as _i44;
import 'package:your_space_mobile/features/auth/presentation/cubit/reset_password_cubit/reset_password_cubit.dart'
    as _i115;
import 'package:your_space_mobile/features/classification/data/datasources/base_city_data_source.dart'
    as _i97;
import 'package:your_space_mobile/features/classification/data/datasources/base_governorate_data_source.dart'
    as _i721;
import 'package:your_space_mobile/features/classification/data/datasources/base_neighborhood_data_source.dart'
    as _i423;
import 'package:your_space_mobile/features/classification/data/datasources/base_subgroup_data_source.dart'
    as _i148;
import 'package:your_space_mobile/features/classification/data/datasources/city_local_data_source_impl.dart'
    as _i741;
import 'package:your_space_mobile/features/classification/data/datasources/city_remote_data_source_impl.dart'
    as _i500;
import 'package:your_space_mobile/features/classification/data/datasources/governorate_local_data_source_impl.dart'
    as _i577;
import 'package:your_space_mobile/features/classification/data/datasources/governorate_remote_data_source_impl.dart'
    as _i352;
import 'package:your_space_mobile/features/classification/data/datasources/neighborhood_local_data_source_impl.dart'
    as _i581;
import 'package:your_space_mobile/features/classification/data/datasources/neighborhood_remote_data_source_impl.dart'
    as _i46;
import 'package:your_space_mobile/features/classification/data/datasources/subgroup_local_data_source_impl.dart'
    as _i363;
import 'package:your_space_mobile/features/classification/data/datasources/subgroup_remote_data_source_impl.dart'
    as _i566;
import 'package:your_space_mobile/features/classification/data/repositories/city_repository_impl.dart'
    as _i866;
import 'package:your_space_mobile/features/classification/data/repositories/governorate_repository_impl.dart'
    as _i362;
import 'package:your_space_mobile/features/classification/data/repositories/neighborhood_repository_impl.dart'
    as _i412;
import 'package:your_space_mobile/features/classification/data/repositories/subgroup_repository_impl.dart'
    as _i180;
import 'package:your_space_mobile/features/classification/data/sync/city_collection_puller.dart'
    as _i975;
import 'package:your_space_mobile/features/classification/data/sync/city_outbox_replayer.dart'
    as _i682;
import 'package:your_space_mobile/features/classification/data/sync/governorate_collection_puller.dart'
    as _i1067;
import 'package:your_space_mobile/features/classification/data/sync/governorate_outbox_replayer.dart'
    as _i774;
import 'package:your_space_mobile/features/classification/data/sync/neighborhood_collection_puller.dart'
    as _i236;
import 'package:your_space_mobile/features/classification/data/sync/neighborhood_outbox_replayer.dart'
    as _i279;
import 'package:your_space_mobile/features/classification/data/sync/subgroup_collection_puller.dart'
    as _i643;
import 'package:your_space_mobile/features/classification/data/sync/subgroup_outbox_replayer.dart'
    as _i1023;
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart'
    as _i881;
import 'package:your_space_mobile/features/classification/domain/repositories/base_governorate_repository.dart'
    as _i262;
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart'
    as _i681;
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart'
    as _i133;
import 'package:your_space_mobile/features/classification/presentation/cubit/city_action_cubit/city_action_cubit.dart'
    as _i837;
import 'package:your_space_mobile/features/classification/presentation/cubit/city_list_cubit/city_list_cubit.dart'
    as _i493;
import 'package:your_space_mobile/features/classification/presentation/cubit/neighborhood_action_cubit/neighborhood_action_cubit.dart'
    as _i623;
import 'package:your_space_mobile/features/classification/presentation/cubit/neighborhood_list_cubit/neighborhood_list_cubit.dart'
    as _i977;
import 'package:your_space_mobile/features/classification/presentation/cubit/subgroup_action_cubit/subgroup_action_cubit.dart'
    as _i793;
import 'package:your_space_mobile/features/classification/presentation/cubit/subgroup_list_cubit/subgroup_list_cubit.dart'
    as _i157;
import 'package:your_space_mobile/features/events/data/datasources/base_event_data_source.dart'
    as _i416;
import 'package:your_space_mobile/features/events/data/datasources/base_event_guest_data_source.dart'
    as _i738;
import 'package:your_space_mobile/features/events/data/datasources/event_guest_local_data_source_impl.dart'
    as _i607;
import 'package:your_space_mobile/features/events/data/datasources/event_guest_remote_data_source_impl.dart'
    as _i320;
import 'package:your_space_mobile/features/events/data/datasources/event_local_data_source_impl.dart'
    as _i527;
import 'package:your_space_mobile/features/events/data/datasources/event_remote_data_source_impl.dart'
    as _i557;
import 'package:your_space_mobile/features/events/data/repositories/event_guest_repository_impl.dart'
    as _i1063;
import 'package:your_space_mobile/features/events/data/repositories/event_repository_impl.dart'
    as _i155;
import 'package:your_space_mobile/features/events/data/sync/event_collection_puller.dart'
    as _i509;
import 'package:your_space_mobile/features/events/data/sync/event_guest_collection_puller.dart'
    as _i379;
import 'package:your_space_mobile/features/events/data/sync/event_guest_outbox_replayer.dart'
    as _i51;
import 'package:your_space_mobile/features/events/data/sync/event_outbox_replayer.dart'
    as _i149;
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
import 'package:your_space_mobile/features/groups/data/datasources/base_group_data_source.dart'
    as _i229;
import 'package:your_space_mobile/features/groups/data/datasources/group_local_data_source_impl.dart'
    as _i640;
import 'package:your_space_mobile/features/groups/data/datasources/group_remote_data_source_impl.dart'
    as _i190;
import 'package:your_space_mobile/features/groups/data/repositories/group_repository_impl.dart'
    as _i612;
import 'package:your_space_mobile/features/groups/data/sync/group_collection_puller.dart'
    as _i544;
import 'package:your_space_mobile/features/groups/data/sync/group_outbox_replayer.dart'
    as _i1011;
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart'
    as _i994;
import 'package:your_space_mobile/features/groups/presentation/cubit/group_action_cubit/group_action_cubit.dart'
    as _i965;
import 'package:your_space_mobile/features/groups/presentation/cubit/groups_list_cubit/groups_list_cubit.dart'
    as _i771;
import 'package:your_space_mobile/features/home/presentation/cubit/home_stats_cubit/home_stats_cubit.dart'
    as _i136;
import 'package:your_space_mobile/features/people/data/datasources/base_person_data_source.dart'
    as _i498;
import 'package:your_space_mobile/features/people/data/datasources/base_person_image_data_source.dart'
    as _i1004;
import 'package:your_space_mobile/features/people/data/datasources/base_person_relationship_data_source.dart'
    as _i1008;
import 'package:your_space_mobile/features/people/data/datasources/person_image_local_data_source_impl.dart'
    as _i836;
import 'package:your_space_mobile/features/people/data/datasources/person_image_remote_data_source_impl.dart'
    as _i931;
import 'package:your_space_mobile/features/people/data/datasources/person_local_data_source_impl.dart'
    as _i439;
import 'package:your_space_mobile/features/people/data/datasources/person_relationship_local_data_source_impl.dart'
    as _i732;
import 'package:your_space_mobile/features/people/data/datasources/person_relationship_remote_data_source_impl.dart'
    as _i903;
import 'package:your_space_mobile/features/people/data/datasources/person_remote_data_source_impl.dart'
    as _i293;
import 'package:your_space_mobile/features/people/data/repositories/person_image_repository_impl.dart'
    as _i744;
import 'package:your_space_mobile/features/people/data/repositories/person_relationship_repository_impl.dart'
    as _i630;
import 'package:your_space_mobile/features/people/data/repositories/person_repository_impl.dart'
    as _i504;
import 'package:your_space_mobile/features/people/data/sync/person_collection_puller.dart'
    as _i946;
import 'package:your_space_mobile/features/people/data/sync/person_image_collection_puller.dart'
    as _i415;
import 'package:your_space_mobile/features/people/data/sync/person_image_outbox_replayer.dart'
    as _i815;
import 'package:your_space_mobile/features/people/data/sync/person_outbox_replayer.dart'
    as _i622;
import 'package:your_space_mobile/features/people/data/sync/person_relationship_collection_puller.dart'
    as _i816;
import 'package:your_space_mobile/features/people/data/sync/person_relationship_outbox_replayer.dart'
    as _i66;
import 'package:your_space_mobile/features/people/domain/repositories/base_person_image_repository.dart'
    as _i1005;
import 'package:your_space_mobile/features/people/domain/repositories/base_person_relationship_repository.dart'
    as _i126;
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart'
    as _i571;
import 'package:your_space_mobile/features/people/presentation/cubit/add_occasion_cubit/add_occasion_cubit.dart'
    as _i641;
import 'package:your_space_mobile/features/people/presentation/cubit/people_list_cubit/people_list_cubit.dart'
    as _i512;
import 'package:your_space_mobile/features/people/presentation/cubit/person_details_cubit/person_details_cubit.dart'
    as _i930;
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/person_wizard_cubit.dart'
    as _i68;
import 'package:your_space_mobile/features/settings/presentation/cubit/profile_form_cubit/profile_form_cubit.dart'
    as _i291;

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
    gh.lazySingleton<_i935.AppDatabase>(() => _i935.AppDatabase());
    gh.lazySingleton<List<_i222.OutboxReplayer>>(
      () => registerModule.outboxReplayers,
    );
    gh.lazySingleton<List<_i635.CollectionPuller>>(
      () => registerModule.collectionPullers,
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i215.DataRefreshBus>(
      () => _i215.DataRefreshBus(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i0.ConnectivityHelper>(() => _i0.ConnectivityHelper());
    gh.lazySingleton<_i134.SecureStorageHelper>(
      () => _i134.SecureStorageHelper(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i782.AppPreferencesHelper>(
      () => _i782.AppPreferencesHelper(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i583.GoRouter>(
      () => registerModule.router(gh<_i718.GlobalKey<_i718.NavigatorState>>()),
    );
    gh.lazySingleton<_i559.LocaleHelper>(
      () => _i559.LocaleHelper(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i741.CityLocalDataSourceImpl>(
      () => _i741.CityLocalDataSourceImpl(gh<_i935.AppDatabase>()),
      instanceName: 'local',
    );
    gh.lazySingleton<_i577.GovernorateLocalDataSourceImpl>(
      () => _i577.GovernorateLocalDataSourceImpl(gh<_i935.AppDatabase>()),
      instanceName: 'local',
    );
    gh.lazySingleton<_i581.NeighborhoodLocalDataSourceImpl>(
      () => _i581.NeighborhoodLocalDataSourceImpl(gh<_i935.AppDatabase>()),
      instanceName: 'local',
    );
    gh.lazySingleton<_i363.SubGroupLocalDataSourceImpl>(
      () => _i363.SubGroupLocalDataSourceImpl(gh<_i935.AppDatabase>()),
      instanceName: 'local',
    );
    gh.lazySingleton<_i607.EventGuestLocalDataSourceImpl>(
      () => _i607.EventGuestLocalDataSourceImpl(gh<_i935.AppDatabase>()),
      instanceName: 'local',
    );
    gh.lazySingleton<_i527.EventLocalDataSourceImpl>(
      () => _i527.EventLocalDataSourceImpl(gh<_i935.AppDatabase>()),
      instanceName: 'local',
    );
    gh.lazySingleton<_i640.GroupLocalDataSourceImpl>(
      () => _i640.GroupLocalDataSourceImpl(gh<_i935.AppDatabase>()),
      instanceName: 'local',
    );
    gh.lazySingleton<_i836.PersonImageLocalDataSourceImpl>(
      () => _i836.PersonImageLocalDataSourceImpl(gh<_i935.AppDatabase>()),
      instanceName: 'local',
    );
    gh.lazySingleton<_i439.PersonLocalDataSourceImpl>(
      () => _i439.PersonLocalDataSourceImpl(gh<_i935.AppDatabase>()),
      instanceName: 'local',
    );
    gh.lazySingleton<_i732.PersonRelationshipLocalDataSourceImpl>(
      () =>
          _i732.PersonRelationshipLocalDataSourceImpl(gh<_i935.AppDatabase>()),
      instanceName: 'local',
    );
    gh.lazySingleton<_i733.DialogHelper>(
      () => _i733.DialogHelper(gh<_i409.GlobalKey<_i409.NavigatorState>>()),
    );
    gh.lazySingleton<_i967.SnackBarHelper>(
      () => _i967.SnackBarHelper(gh<_i409.GlobalKey<_i409.NavigatorState>>()),
    );
    gh.lazySingleton<_i477.SyncService>(
      () => _i477.SyncService(
        gh<_i935.AppDatabase>(),
        gh<_i0.ConnectivityHelper>(),
        gh<List<_i222.OutboxReplayer>>(),
        gh<List<_i635.CollectionPuller>>(),
      ),
      dispose: (i) => i.dispose(),
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
    gh.lazySingleton<_i1004.BasePersonImageDataSource>(
      () => _i931.PersonImageRemoteDataSourceImpl(gh<_i531.ApiManager>()),
      instanceName: 'remote',
    );
    gh.lazySingleton<_i148.BaseSubGroupDataSource>(
      () => _i566.SubGroupRemoteDataSourceImpl(gh<_i531.ApiManager>()),
      instanceName: 'remote',
    );
    gh.lazySingleton<_i1005.PersonImageRepository>(
      () => _i744.PersonImageRepositoryImpl(
        gh<_i1004.BasePersonImageDataSource>(instanceName: 'remote'),
        gh<_i836.PersonImageLocalDataSourceImpl>(instanceName: 'local'),
        gh<_i477.SyncService>(),
      ),
    );
    gh.lazySingleton<_i222.OutboxReplayer>(
      () => _i815.PersonImageOutboxReplayer(
        gh<_i1004.BasePersonImageDataSource>(instanceName: 'remote'),
        gh<_i836.PersonImageLocalDataSourceImpl>(instanceName: 'local'),
      ),
      instanceName: 'personImage',
    );
    gh.lazySingleton<_i222.OutboxReplayer>(
      () => _i1023.SubGroupOutboxReplayer(
        gh<_i148.BaseSubGroupDataSource>(instanceName: 'remote'),
        gh<_i363.SubGroupLocalDataSourceImpl>(instanceName: 'local'),
      ),
      instanceName: 'subgroup',
    );
    gh.lazySingleton<_i133.SubGroupRepository>(
      () => _i180.SubGroupRepositoryImpl(
        gh<_i148.BaseSubGroupDataSource>(instanceName: 'remote'),
        gh<_i363.SubGroupLocalDataSourceImpl>(instanceName: 'local'),
        gh<_i477.SyncService>(),
      ),
    );
    gh.lazySingleton<_i498.BasePersonDataSource>(
      () => _i293.PersonRemoteDataSourceImpl(gh<_i531.ApiManager>()),
      instanceName: 'remote',
    );
    gh.lazySingleton<_i229.BaseGroupDataSource>(
      () => _i190.GroupRemoteDataSourceImpl(gh<_i531.ApiManager>()),
      instanceName: 'remote',
    );
    gh.lazySingleton<_i97.BaseCityDataSource>(
      () => _i500.CityRemoteDataSourceImpl(gh<_i531.ApiManager>()),
      instanceName: 'remote',
    );
    gh.lazySingleton<_i635.CollectionPuller>(
      () =>
          _i415.PersonImageCollectionPuller(gh<_i1005.PersonImageRepository>()),
      instanceName: 'personImage',
    );
    gh.lazySingleton<_i1073.AuthRemoteDataSourceImpl>(
      () => _i1073.AuthRemoteDataSourceImpl(gh<_i531.ApiManager>()),
    );
    gh.lazySingleton<_i423.BaseNeighborhoodDataSource>(
      () => _i46.NeighborhoodRemoteDataSourceImpl(gh<_i531.ApiManager>()),
      instanceName: 'remote',
    );
    gh.lazySingleton<_i571.PersonRepository>(
      () => _i504.PersonRepositoryImpl(
        gh<_i498.BasePersonDataSource>(instanceName: 'remote'),
        gh<_i439.PersonLocalDataSourceImpl>(instanceName: 'local'),
        gh<_i477.SyncService>(),
      ),
    );
    gh.lazySingleton<_i738.BaseEventGuestDataSource>(
      () => _i320.EventGuestRemoteDataSourceImpl(gh<_i531.ApiManager>()),
      instanceName: 'remote',
    );
    gh.lazySingleton<_i635.CollectionPuller>(
      () => _i643.SubGroupCollectionPuller(gh<_i133.SubGroupRepository>()),
      instanceName: 'subgroup',
    );
    gh.factory<_i641.AddOccasionCubit>(
      () => _i641.AddOccasionCubit(gh<_i571.PersonRepository>()),
    );
    gh.factory<_i793.SubGroupActionCubit>(
      () => _i793.SubGroupActionCubit(gh<_i133.SubGroupRepository>()),
    );
    gh.factory<_i157.SubGroupListCubit>(
      () => _i157.SubGroupListCubit(gh<_i133.SubGroupRepository>()),
    );
    gh.lazySingleton<_i635.CollectionPuller>(
      () => _i946.PersonCollectionPuller(gh<_i571.PersonRepository>()),
      instanceName: 'person',
    );
    gh.lazySingleton<_i416.BaseEventDataSource>(
      () => _i557.EventRemoteDataSourceImpl(gh<_i531.ApiManager>()),
      instanceName: 'remote',
    );
    gh.lazySingleton<_i721.BaseGovernorateDataSource>(
      () => _i352.GovernorateRemoteDataSourceImpl(gh<_i531.ApiManager>()),
      instanceName: 'remote',
    );
    gh.lazySingleton<_i1008.BasePersonRelationshipDataSource>(
      () =>
          _i903.PersonRelationshipRemoteDataSourceImpl(gh<_i531.ApiManager>()),
      instanceName: 'remote',
    );
    gh.lazySingleton<_i219.EventRepository>(
      () => _i155.EventRepositoryImpl(
        gh<_i416.BaseEventDataSource>(instanceName: 'remote'),
        gh<_i527.EventLocalDataSourceImpl>(instanceName: 'local'),
      ),
    );
    gh.lazySingleton<_i262.GovernorateRepository>(
      () => _i362.GovernorateRepositoryImpl(
        gh<_i721.BaseGovernorateDataSource>(instanceName: 'remote'),
        gh<_i577.GovernorateLocalDataSourceImpl>(instanceName: 'local'),
        gh<_i477.SyncService>(),
      ),
    );
    gh.factory<_i930.PersonDetailsCubit>(
      () => _i930.PersonDetailsCubit(
        gh<_i571.PersonRepository>(),
        gh<_i215.DataRefreshBus>(),
      ),
    );
    gh.lazySingleton<_i235.EventGuestRepository>(
      () => _i1063.EventGuestRepositoryImpl(
        gh<_i738.BaseEventGuestDataSource>(instanceName: 'remote'),
        gh<_i607.EventGuestLocalDataSourceImpl>(instanceName: 'local'),
        gh<_i571.PersonRepository>(),
      ),
    );
    gh.lazySingleton<_i222.OutboxReplayer>(
      () => _i622.PersonOutboxReplayer(
        gh<_i498.BasePersonDataSource>(instanceName: 'remote'),
        gh<_i439.PersonLocalDataSourceImpl>(instanceName: 'local'),
      ),
      instanceName: 'person',
    );
    gh.lazySingleton<_i994.GroupRepository>(
      () => _i612.GroupRepositoryImpl(
        gh<_i229.BaseGroupDataSource>(instanceName: 'remote'),
        gh<_i640.GroupLocalDataSourceImpl>(instanceName: 'local'),
        gh<_i477.SyncService>(),
      ),
    );
    gh.lazySingleton<_i881.CityRepository>(
      () => _i866.CityRepositoryImpl(
        gh<_i97.BaseCityDataSource>(instanceName: 'remote'),
        gh<_i741.CityLocalDataSourceImpl>(instanceName: 'local'),
        gh<_i477.SyncService>(),
      ),
    );
    gh.factory<_i837.CityActionCubit>(
      () => _i837.CityActionCubit(gh<_i881.CityRepository>()),
    );
    gh.factory<_i493.CityListCubit>(
      () => _i493.CityListCubit(gh<_i881.CityRepository>()),
    );
    gh.lazySingleton<_i680.AuthRepository>(
      () => _i722.AuthRepositoryImpl(
        gh<_i1073.AuthRemoteDataSourceImpl>(),
        gh<_i134.SecureStorageHelper>(),
      ),
    );
    gh.lazySingleton<_i635.CollectionPuller>(
      () => _i509.EventCollectionPuller(gh<_i219.EventRepository>()),
      instanceName: 'event',
    );
    gh.factory<_i755.EventFormCubit>(
      () => _i755.EventFormCubit(gh<_i219.EventRepository>()),
    );
    gh.lazySingleton<_i635.CollectionPuller>(
      () => _i975.CityCollectionPuller(gh<_i881.CityRepository>()),
      instanceName: 'city',
    );
    gh.lazySingleton<_i681.NeighborhoodRepository>(
      () => _i412.NeighborhoodRepositoryImpl(
        gh<_i423.BaseNeighborhoodDataSource>(instanceName: 'remote'),
        gh<_i581.NeighborhoodLocalDataSourceImpl>(instanceName: 'local'),
        gh<_i477.SyncService>(),
      ),
    );
    gh.lazySingleton<_i222.OutboxReplayer>(
      () => _i149.EventOutboxReplayer(
        gh<_i416.BaseEventDataSource>(instanceName: 'remote'),
        gh<_i527.EventLocalDataSourceImpl>(instanceName: 'local'),
      ),
      instanceName: 'event',
    );
    gh.lazySingleton<_i222.OutboxReplayer>(
      () => _i1011.GroupOutboxReplayer(
        gh<_i229.BaseGroupDataSource>(instanceName: 'remote'),
        gh<_i640.GroupLocalDataSourceImpl>(instanceName: 'local'),
      ),
      instanceName: 'group',
    );
    gh.factory<_i623.NeighborhoodActionCubit>(
      () => _i623.NeighborhoodActionCubit(gh<_i681.NeighborhoodRepository>()),
    );
    gh.factory<_i977.NeighborhoodListCubit>(
      () => _i977.NeighborhoodListCubit(gh<_i681.NeighborhoodRepository>()),
    );
    gh.lazySingleton<_i222.OutboxReplayer>(
      () => _i682.CityOutboxReplayer(
        gh<_i97.BaseCityDataSource>(instanceName: 'remote'),
        gh<_i741.CityLocalDataSourceImpl>(instanceName: 'local'),
      ),
      instanceName: 'city',
    );
    gh.factory<_i391.EventDetailsCubit>(
      () => _i391.EventDetailsCubit(
        gh<_i219.EventRepository>(),
        gh<_i235.EventGuestRepository>(),
        gh<_i215.DataRefreshBus>(),
      ),
    );
    gh.factory<_i426.AddGuestsActionCubit>(
      () => _i426.AddGuestsActionCubit(gh<_i235.EventGuestRepository>()),
    );
    gh.factory<_i410.EventGuestActionCubit>(
      () => _i410.EventGuestActionCubit(gh<_i235.EventGuestRepository>()),
    );
    gh.lazySingleton<_i635.CollectionPuller>(
      () => _i236.NeighborhoodCollectionPuller(
        gh<_i681.NeighborhoodRepository>(),
      ),
      instanceName: 'neighborhood',
    );
    gh.factory<_i512.PeopleListCubit>(
      () => _i512.PeopleListCubit(
        gh<_i571.PersonRepository>(),
        gh<_i994.GroupRepository>(),
        gh<_i133.SubGroupRepository>(),
        gh<_i262.GovernorateRepository>(),
        gh<_i881.CityRepository>(),
        gh<_i681.NeighborhoodRepository>(),
        gh<_i215.DataRefreshBus>(),
      ),
    );
    gh.lazySingleton<_i635.CollectionPuller>(
      () =>
          _i1067.GovernorateCollectionPuller(gh<_i262.GovernorateRepository>()),
      instanceName: 'governorate',
    );
    gh.lazySingleton<_i222.OutboxReplayer>(
      () => _i279.NeighborhoodOutboxReplayer(
        gh<_i423.BaseNeighborhoodDataSource>(instanceName: 'remote'),
        gh<_i581.NeighborhoodLocalDataSourceImpl>(instanceName: 'local'),
      ),
      instanceName: 'neighborhood',
    );
    gh.lazySingleton<_i222.OutboxReplayer>(
      () => _i51.EventGuestOutboxReplayer(
        gh<_i738.BaseEventGuestDataSource>(instanceName: 'remote'),
        gh<_i607.EventGuestLocalDataSourceImpl>(instanceName: 'local'),
      ),
      instanceName: 'eventGuest',
    );
    gh.factory<_i965.GroupActionCubit>(
      () => _i965.GroupActionCubit(gh<_i994.GroupRepository>()),
    );
    gh.factory<_i771.GroupsListCubit>(
      () => _i771.GroupsListCubit(gh<_i994.GroupRepository>()),
    );
    gh.lazySingleton<_i126.PersonRelationshipRepository>(
      () => _i630.PersonRelationshipRepositoryImpl(
        gh<_i1008.BasePersonRelationshipDataSource>(instanceName: 'remote'),
        gh<_i732.PersonRelationshipLocalDataSourceImpl>(instanceName: 'local'),
        gh<_i571.PersonRepository>(),
      ),
    );
    gh.lazySingleton<_i222.OutboxReplayer>(
      () => _i774.GovernorateOutboxReplayer(
        gh<_i721.BaseGovernorateDataSource>(instanceName: 'remote'),
        gh<_i577.GovernorateLocalDataSourceImpl>(instanceName: 'local'),
      ),
      instanceName: 'governorate',
    );
    gh.lazySingleton<_i222.OutboxReplayer>(
      () => _i66.PersonRelationshipOutboxReplayer(
        gh<_i1008.BasePersonRelationshipDataSource>(instanceName: 'remote'),
        gh<_i732.PersonRelationshipLocalDataSourceImpl>(instanceName: 'local'),
      ),
      instanceName: 'personRelationship',
    );
    gh.factory<_i895.AddGuestsListCubit>(
      () => _i895.AddGuestsListCubit(
        gh<_i571.PersonRepository>(),
        gh<_i235.EventGuestRepository>(),
        gh<_i133.SubGroupRepository>(),
        gh<_i262.GovernorateRepository>(),
        gh<_i881.CityRepository>(),
        gh<_i681.NeighborhoodRepository>(),
      ),
    );
    gh.factory<_i1019.ChangePasswordCubit>(
      () => _i1019.ChangePasswordCubit(gh<_i680.AuthRepository>()),
    );
    gh.factory<_i723.ConfirmEmailCubit>(
      () => _i723.ConfirmEmailCubit(gh<_i680.AuthRepository>()),
    );
    gh.factory<_i516.DeleteAccountCubit>(
      () => _i516.DeleteAccountCubit(gh<_i680.AuthRepository>()),
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
    gh.factory<_i890.EventsListCubit>(
      () => _i890.EventsListCubit(
        gh<_i219.EventRepository>(),
        gh<_i215.DataRefreshBus>(),
      ),
    );
    gh.lazySingleton<_i635.CollectionPuller>(
      () => _i379.EventGuestCollectionPuller(gh<_i235.EventGuestRepository>()),
      instanceName: 'eventGuest',
    );
    gh.lazySingleton<_i635.CollectionPuller>(
      () => _i544.GroupCollectionPuller(gh<_i994.GroupRepository>()),
      instanceName: 'group',
    );
    gh.factory<_i84.GetCurrentUserProfileUseCase>(
      () => _i84.GetCurrentUserProfileUseCase(gh<_i680.AuthRepository>()),
    );
    gh.lazySingleton<_i635.CollectionPuller>(
      () => _i816.PersonRelationshipCollectionPuller(
        gh<_i126.PersonRelationshipRepository>(),
      ),
      instanceName: 'personRelationship',
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
    gh.factory<_i68.PersonWizardCubit>(
      () => _i68.PersonWizardCubit(
        gh<_i571.PersonRepository>(),
        gh<_i994.GroupRepository>(),
        gh<_i133.SubGroupRepository>(),
        gh<_i262.GovernorateRepository>(),
        gh<_i881.CityRepository>(),
        gh<_i681.NeighborhoodRepository>(),
        gh<_i1005.PersonImageRepository>(),
        gh<_i126.PersonRelationshipRepository>(),
        gh<_i215.DataRefreshBus>(),
      ),
    );
    gh.factory<_i291.ProfileFormCubit>(
      () => _i291.ProfileFormCubit(
        gh<_i84.GetCurrentUserProfileUseCase>(),
        gh<_i680.AuthRepository>(),
        gh<_i215.DataRefreshBus>(),
      ),
    );
    gh.factory<_i136.HomeStatsCubit>(
      () => _i136.HomeStatsCubit(
        gh<_i994.GroupRepository>(),
        gh<_i571.PersonRepository>(),
        gh<_i219.EventRepository>(),
        gh<_i84.GetCurrentUserProfileUseCase>(),
        gh<_i215.DataRefreshBus>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i876.RegisterModule {}

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/dio_factory.dart';
import '../router/app_router.dart';
import '../sync/collection_puller.dart';
import '../sync/outbox_replayer.dart';

@module
abstract class RegisterModule {
  // `SyncService` (core/sync/sync_service.dart) wants `List<OutboxReplayer>`/
  // `List<CollectionPuller>`, but injectable's generated `gh<List<T>>()` call
  // resolves straight against get_it's own type registry, which has no
  // built-in notion of "every implementation of interface T" — there is no
  // real registration under the literal type `List<OutboxReplayer>` unless
  // something provides one. Each per-entity `OutboxReplayer`/`CollectionPuller`
  // implementation tags itself with a distinct `@Named` (see
  // `PersonOutboxReplayer`'s doc comment) precisely so they can coexist here:
  // `GetIt.getAll<T>()` collects every registration assignable to `T`
  // regardless of instance name.
  @lazySingleton
  List<OutboxReplayer> get outboxReplayers => GetIt.instance.getAll<OutboxReplayer>().toList();

  @lazySingleton
  List<CollectionPuller> get collectionPullers => GetIt.instance.getAll<CollectionPuller>().toList();

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

import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_event_repository.dart';

/// `SyncService`'s collection: 'events' strategy — a thin wrapper over
/// `EventRepository.refreshEvents()`. Mirrors `CityCollectionPuller`. See
/// `PersonOutboxReplayer`'s doc comment for why the `@Named` tag exists.
///
/// Resolves [EventRepository] lazily via [GetIt] at pull time, matching
/// every other `CollectionPuller` — see `PersonCollectionPuller`'s doc
/// comment for why constructor injection recreates a circular dependency
/// with `SyncService` for repositories that depend on it.
@Named('event')
@LazySingleton(as: CollectionPuller)
class EventCollectionPuller implements CollectionPuller {
  @override
  String get collection => 'events';

  @override
  Future<Either<Failure, Unit>> pull() =>
      GetIt.instance<EventRepository>().refreshEvents();
}

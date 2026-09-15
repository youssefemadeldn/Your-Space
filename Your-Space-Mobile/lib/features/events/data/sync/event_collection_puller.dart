import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_event_repository.dart';

/// `SyncService`'s collection: 'events' strategy — a thin wrapper over
/// `EventRepository.refreshEvents()`. Mirrors `CityCollectionPuller`. See
/// `PersonOutboxReplayer`'s doc comment for why the `@Named` tag exists.
@Named('event')
@LazySingleton(as: CollectionPuller)
class EventCollectionPuller implements CollectionPuller {
  final EventRepository _eventRepository;

  EventCollectionPuller(this._eventRepository);

  @override
  String get collection => 'events';

  @override
  Future<Either<Failure, Unit>> pull() => _eventRepository.refreshEvents();
}

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_event_guest_repository.dart';

/// `SyncService`'s collection: 'eventGuests' strategy — a thin wrapper over
/// `EventGuestRepository.refreshEventGuests()`, which is EventGuest's
/// **permanent** full-refetch-as-delta pull (row 9 cross-cutting decision —
/// never superseded by a cursor-based step, unlike every other entity's own
/// collection puller). Mirrors `CityCollectionPuller`.
@Named('eventGuest')
@LazySingleton(as: CollectionPuller)
class EventGuestCollectionPuller implements CollectionPuller {
  final EventGuestRepository _eventGuestRepository;

  EventGuestCollectionPuller(this._eventGuestRepository);

  @override
  String get collection => 'eventGuests';

  @override
  Future<Either<Failure, Unit>> pull() => _eventGuestRepository.refreshEventGuests();
}

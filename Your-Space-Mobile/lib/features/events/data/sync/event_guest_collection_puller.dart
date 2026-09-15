import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_event_guest_repository.dart';

/// `SyncService`'s collection: 'eventGuests' strategy — a thin wrapper over
/// `EventGuestRepository.refreshEventGuests()`, which is EventGuest's
/// **permanent** full-refetch-as-delta pull (row 9 cross-cutting decision —
/// never superseded by a cursor-based step, unlike every other entity's own
/// collection puller). Mirrors `CityCollectionPuller`.
///
/// Resolves [EventGuestRepository] lazily via [GetIt] at pull time — see
/// `PersonCollectionPuller`'s doc comment for why constructor injection here
/// would recreate a circular dependency with `SyncService`.
@Named('eventGuest')
@LazySingleton(as: CollectionPuller)
class EventGuestCollectionPuller implements CollectionPuller {
  @override
  String get collection => 'eventGuests';

  @override
  Future<Either<Failure, Unit>> pull() =>
      GetIt.instance<EventGuestRepository>().refreshEventGuests();
}

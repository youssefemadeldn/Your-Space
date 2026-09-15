import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_person_repository.dart';

/// `SyncService`'s collection: 'persons' strategy — a thin wrapper over
/// `PersonRepository.refreshPersons()`, which already does the fetch +
/// diff/tombstone work (Tier 3, design doc §6).
///
/// The `@Named` tag mirrors `PersonOutboxReplayer`'s (see its doc comment):
/// it reserves this registration's identity so a future second
/// `CollectionPuller` implementation (e.g. Groups' row 7.4) doesn't collide
/// with it under injectable's duplicate-registration check.
/// `RegisterModule.collectionPullers` collects every tagged `CollectionPuller`
/// back into the `List<CollectionPuller>` `SyncService` actually wants.
/// Resolves [PersonRepository] lazily via [GetIt] at pull time rather than
/// through constructor injection: `PersonRepositoryImpl` depends on
/// `SyncService`, and `SyncService`'s own construction eagerly builds every
/// registered `CollectionPuller` (via `RegisterModule.collectionPullers`) —
/// a constructor-injected repository here would recreate that cycle.
@Named('person')
@LazySingleton(as: CollectionPuller)
class PersonCollectionPuller implements CollectionPuller {
  @override
  String get collection => 'persons';

  @override
  Future<Either<Failure, Unit>> pull() =>
      GetIt.instance<PersonRepository>().refreshPersons();
}

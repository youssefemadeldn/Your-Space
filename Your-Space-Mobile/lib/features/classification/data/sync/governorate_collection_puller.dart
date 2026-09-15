import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_governorate_repository.dart';

/// `SyncService`'s collection: 'governorates' strategy — a thin wrapper over
/// `GovernorateRepository.refreshGovernorates()`, which already does the
/// fetch + diff/tombstone work (Tier 3, design doc §6). Mirrors
/// `GroupCollectionPuller`.
///
/// See `PersonOutboxReplayer`'s doc comment for why the `@Named` tag exists:
/// it reserves this registration's identity so it can coexist with the
/// other entities' pullers under injectable's duplicate-registration check.
/// `RegisterModule.collectionPullers` collects all of them back into the
/// `List<CollectionPuller>` `SyncService` actually wants.
/// Resolves [GovernorateRepository] lazily via [GetIt] at pull time — see
/// `PersonCollectionPuller`'s doc comment for why constructor injection here
/// would recreate a circular dependency with `SyncService`.
@Named('governorate')
@LazySingleton(as: CollectionPuller)
class GovernorateCollectionPuller implements CollectionPuller {
  @override
  String get collection => 'governorates';

  @override
  Future<Either<Failure, Unit>> pull() =>
      GetIt.instance<GovernorateRepository>().refreshGovernorates();
}

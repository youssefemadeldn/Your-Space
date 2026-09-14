import 'package:dartz/dartz.dart';
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
@Named('governorate')
@LazySingleton(as: CollectionPuller)
class GovernorateCollectionPuller implements CollectionPuller {
  final GovernorateRepository _governorateRepository;

  GovernorateCollectionPuller(this._governorateRepository);

  @override
  String get collection => 'governorates';

  @override
  Future<Either<Failure, Unit>> pull() => _governorateRepository.refreshGovernorates();
}

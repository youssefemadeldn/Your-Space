import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_subgroup_repository.dart';

/// `SyncService`'s collection: 'subgroups' strategy — a thin wrapper over
/// `SubGroupRepository.refreshSubGroups()`, which already does the fetch +
/// diff/tombstone work (Tier 3 interim mode, design doc §6, row 8.16).
/// Mirrors `CityCollectionPuller`.
///
/// See `PersonOutboxReplayer`'s doc comment for why the `@Named` tag exists:
/// it reserves this registration's identity so it can coexist with the
/// other entities' pullers under injectable's duplicate-registration check.
/// `RegisterModule.collectionPullers` collects all of them back into the
/// `List<CollectionPuller>` `SyncService` actually wants.
@Named('subgroup')
@LazySingleton(as: CollectionPuller)
class SubGroupCollectionPuller implements CollectionPuller {
  final SubGroupRepository _subGroupRepository;

  SubGroupCollectionPuller(this._subGroupRepository);

  @override
  String get collection => 'subgroups';

  @override
  Future<Either<Failure, Unit>> pull() => _subGroupRepository.refreshSubGroups();
}

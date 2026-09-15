import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_group_repository.dart';

/// `SyncService`'s collection: 'groups' strategy — a thin wrapper over
/// `GroupRepository.refreshGroups()`, which already does the fetch +
/// diff/tombstone work (Tier 3, design doc §6). Mirrors `PersonCollectionPuller`.
///
/// See `PersonOutboxReplayer`'s doc comment for why the `@Named` tag exists:
/// it reserves this registration's identity so it can coexist with
/// `PersonCollectionPuller`'s under injectable's duplicate-registration
/// check. `RegisterModule.collectionPullers` collects both back into the
/// `List<CollectionPuller>` `SyncService` actually wants.
/// Resolves [GroupRepository] lazily via [GetIt] at pull time — see
/// `PersonCollectionPuller`'s doc comment for why constructor injection here
/// would recreate a circular dependency with `SyncService`.
@Named('group')
@LazySingleton(as: CollectionPuller)
class GroupCollectionPuller implements CollectionPuller {
  @override
  String get collection => 'groups';

  @override
  Future<Either<Failure, Unit>> pull() =>
      GetIt.instance<GroupRepository>().refreshGroups();
}

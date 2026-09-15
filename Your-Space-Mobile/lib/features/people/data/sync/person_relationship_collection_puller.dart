import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_person_relationship_repository.dart';

/// `SyncService`'s collection: 'personRelationships' strategy — a thin
/// wrapper over `PersonRelationshipRepository.refreshRelationships()`,
/// which is PersonRelationship's **permanent** full-refetch-as-delta pull
/// (row 9 cross-cutting decision). Mirrors `EventGuestCollectionPuller`.
///
/// Resolves [PersonRelationshipRepository] lazily via [GetIt] at pull time —
/// see `PersonCollectionPuller`'s doc comment for why constructor injection
/// here would recreate a circular dependency with `SyncService`.
@Named('personRelationship')
@LazySingleton(as: CollectionPuller)
class PersonRelationshipCollectionPuller implements CollectionPuller {
  @override
  String get collection => 'personRelationships';

  @override
  Future<Either<Failure, Unit>> pull() =>
      GetIt.instance<PersonRelationshipRepository>().refreshRelationships();
}

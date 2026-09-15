import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_person_relationship_repository.dart';

/// `SyncService`'s collection: 'personRelationships' strategy — a thin
/// wrapper over `PersonRelationshipRepository.refreshRelationships()`,
/// which is PersonRelationship's **permanent** full-refetch-as-delta pull
/// (row 9 cross-cutting decision). Mirrors `EventGuestCollectionPuller`.
@Named('personRelationship')
@LazySingleton(as: CollectionPuller)
class PersonRelationshipCollectionPuller implements CollectionPuller {
  final PersonRelationshipRepository _personRelationshipRepository;

  PersonRelationshipCollectionPuller(this._personRelationshipRepository);

  @override
  String get collection => 'personRelationships';

  @override
  Future<Either<Failure, Unit>> pull() => _personRelationshipRepository.refreshRelationships();
}

import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/person_relationship.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';
import 'package:your_space_mobile/core/network/failure.dart';

abstract class PersonRelationshipRepository {
  Future<Either<Failure, List<PersonRelationship>>> getRelationships(int personId);

  Future<Either<Failure, PersonRelationship>> createRelationship({
    required int personId,
    required int relatedPersonId,
    required RelationType relationType,
  });

  Future<Either<Failure, Unit>> deleteRelationship({required int personId, required int relationshipId});
}

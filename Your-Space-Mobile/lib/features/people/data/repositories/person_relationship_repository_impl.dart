import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/person_relationship.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/repositories/base_person_relationship_repository.dart';
import '../datasources/person_relationship_remote_data_source_impl.dart';
import '../models/create_person_relationship_request.dart';

@LazySingleton(as: PersonRelationshipRepository)
class PersonRelationshipRepositoryImpl implements PersonRelationshipRepository {
  final PersonRelationshipRemoteDataSourceImpl _remote;

  PersonRelationshipRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<PersonRelationship>>> getRelationships(int personId) async {
    final result = await _remote.getRelationships(personId);
    return result.fold(Left.new, (list) => Right(list.map((r) => r.toEntity()).toList()));
  }

  @override
  Future<Either<Failure, PersonRelationship>> createRelationship({
    required int personId,
    required int relatedPersonId,
    required RelationType relationType,
  }) async {
    final result = await _remote.createRelationship(
      personId,
      CreatePersonRelationshipRequest(relatedPersonId: relatedPersonId, relationType: relationType),
    );
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, Unit>> deleteRelationship({required int personId, required int relationshipId}) =>
      _remote.deleteRelationship(personId, relationshipId);
}

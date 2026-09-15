import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/person_relationship.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/repositories/base_person_relationship_repository.dart';
import '../../domain/repositories/base_person_repository.dart';
import '../datasources/base_person_relationship_data_source.dart';
import '../datasources/person_relationship_local_data_source_impl.dart';
import '../models/create_person_relationship_request.dart';
import '../relation_inverse_resolver.dart';

const _unboundedLocalLimit = 1000000;

@LazySingleton(as: PersonRelationshipRepository)
class PersonRelationshipRepositoryImpl implements PersonRelationshipRepository {
  final BasePersonRelationshipDataSource _remote;
  final PersonRelationshipLocalDataSourceImpl _local;
  final PersonRepository _personRepository;

  PersonRelationshipRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
    this._personRepository,
  );

  @override
  Future<Either<Failure, List<PersonRelationship>>> getRelationships(int personId) async {
    final result = await _remote.getRelationships(personId);
    return result.fold(Left.new, (list) => Right(list.map((r) => r.toEntity(personId)).toList()));
  }

  @override
  Stream<List<PersonRelationship>> watchRelationships({required int personId, required int limit}) =>
      _local.watchRelationships(personId: personId, limit: limit);

  @override
  Future<Either<Failure, Unit>> refreshRelationships() async {
    final result = await _remote.getAllMinePersonRelationships();
    return result.fold(
      Left.new,
      (responses) async {
        await _local.applyPersonRelationshipsSnapshot(responses.map((r) => r.toEntity()).toList());
        return const Right(unit);
      },
    );
  }

  int _newTempId() => -DateTime.now().microsecondsSinceEpoch;

  @override
  Future<Either<Failure, PersonRelationship>> createRelationship({
    required int personId,
    required int relatedPersonId,
    required RelationType relationType,
  }) async {
    final people = await _personRepository.watchPersons(limit: _unboundedLocalLimit).first;
    final subject = people.where((p) => p.id == personId).firstOrNull;
    final relatedPerson = people.where((p) => p.id == relatedPersonId).firstOrNull;
    final inverseType =
        subject == null ? relationType : RelationInverseResolver.resolve(relationType, subject.gender);

    final forwardId = _newTempId();
    final inverseId = forwardId - 1;

    final forward = PersonRelationship(
      id: forwardId,
      personId: personId,
      relatedPersonId: relatedPersonId,
      relatedPersonName: relatedPerson?.name ?? '',
      relationType: relationType,
      inverseId: inverseId,
    );
    final inverse = PersonRelationship(
      id: inverseId,
      personId: relatedPersonId,
      relatedPersonId: personId,
      relatedPersonName: subject?.name ?? '',
      relationType: inverseType,
      inverseId: forwardId,
    );

    final payloadJson = jsonEncode(
      CreatePersonRelationshipRequest(relatedPersonId: relatedPersonId, relationType: relationType).toJson()
        ..addAll({'personId': personId}),
    );
    await _local.queuePersonRelationshipPair(forward: forward, inverse: inverse, payloadJson: payloadJson);
    return Right(forward);
  }

  @override
  Future<Either<Failure, Unit>> deleteRelationship({required int personId, required int relationshipId}) async {
    await _local.queueDeletedPersonRelationship(relationshipId, payloadJson: jsonEncode({'personId': personId}));
    return const Right(unit);
  }
}

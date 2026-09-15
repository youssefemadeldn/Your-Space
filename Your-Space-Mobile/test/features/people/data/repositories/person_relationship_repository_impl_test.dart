import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/entities/person_relationship.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/people/data/datasources/base_person_relationship_data_source.dart';
import 'package:your_space_mobile/features/people/data/datasources/person_relationship_local_data_source_impl.dart';
import 'package:your_space_mobile/features/people/data/models/create_person_relationship_request.dart';
import 'package:your_space_mobile/features/people/data/models/person_details_response.dart';
import 'package:your_space_mobile/features/people/data/repositories/person_relationship_repository_impl.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

class MockBasePersonRelationshipDataSource extends Mock implements BasePersonRelationshipDataSource {}

class MockPersonRelationshipLocalDataSourceImpl extends Mock implements PersonRelationshipLocalDataSourceImpl {}

class MockPersonRepository extends Mock implements PersonRepository {}

const _youssef = Person(id: 10, name: 'Youssef', gender: Gender.male, groupId: 1, groupName: 'Family', governorateId: 1, governorateName: 'Cairo');
const _ahmed = Person(id: 20, name: 'Ahmed', gender: Gender.male, groupId: 1, groupName: 'Family', governorateId: 1, governorateName: 'Cairo');

void main() {
  late MockBasePersonRelationshipDataSource remote;
  late MockPersonRelationshipLocalDataSourceImpl local;
  late MockPersonRepository personRepository;
  late PersonRelationshipRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const PersonRelationship(id: 0, personId: 0, relatedPersonId: 0, relatedPersonName: '', relationType: RelationType.father));
    registerFallbackValue(const CreatePersonRelationshipRequest(relatedPersonId: 0, relationType: RelationType.father));
  });

  setUp(() {
    remote = MockBasePersonRelationshipDataSource();
    local = MockPersonRelationshipLocalDataSourceImpl();
    personRepository = MockPersonRepository();
    repository = PersonRelationshipRepositoryImpl(remote, local, personRepository);
    when(
      () => local.queuePersonRelationshipPair(
        forward: any(named: 'forward'),
        inverse: any(named: 'inverse'),
        payloadJson: any(named: 'payloadJson'),
      ),
    ).thenAnswer((_) async => 99);
    when(() => local.queueDeletedPersonRelationship(any(), payloadJson: any(named: 'payloadJson')))
        .thenAnswer((_) async {});
    when(() => local.applyPersonRelationshipsSnapshot(any())).thenAnswer((_) async {});
  });

  test('watchRelationships delegates straight to the local data source', () {
    when(() => local.watchRelationships(personId: 10, limit: 20)).thenAnswer(
      (_) => Stream.value(const [
        PersonRelationship(id: 1, personId: 10, relatedPersonId: 20, relatedPersonName: 'Ahmed', relationType: RelationType.father),
      ]),
    );

    final stream = repository.watchRelationships(personId: 10, limit: 20);

    expect(
      stream,
      emits(const [
        PersonRelationship(id: 1, personId: 10, relatedPersonId: 20, relatedPersonName: 'Ahmed', relationType: RelationType.father),
      ]),
    );
  });

  group('createRelationship (symmetric pair, pure optimistic path)', () {
    test('queues both the forward and locally-resolved inverse row via one outbox entry', () async {
      when(() => personRepository.watchPersons(limit: any(named: 'limit')))
          .thenAnswer((_) => Stream.value(const [_youssef, _ahmed]));

      final result = await repository.createRelationship(personId: 10, relatedPersonId: 20, relationType: RelationType.father);

      expect(result.isRight(), isTrue);
      final forward = result.getOrElse(() => throw StateError('expected Right'));
      expect(forward.id, lessThan(0));
      expect(forward.personId, 10);
      expect(forward.relatedPersonId, 20);
      expect(forward.relatedPersonName, 'Ahmed');
      expect(forward.relationType, RelationType.father);

      final captured = verify(
        () => local.queuePersonRelationshipPair(
          forward: captureAny(named: 'forward'),
          inverse: captureAny(named: 'inverse'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      final inverse = captured[1] as PersonRelationship;
      // Male subject's Father -> inverse Son, per RelationInverseResolver, resolved locally.
      expect(inverse.personId, 20);
      expect(inverse.relatedPersonId, 10);
      expect(inverse.relatedPersonName, 'Youssef');
      expect(inverse.relationType, RelationType.son);
      expect(inverse.inverseId, forward.id);
      expect(forward.inverseId, inverse.id);

      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['personId'], 10);
      expect(payload['relatedPersonId'], 20);
      expect(payload['relationType'], 'Father');

      verifyNever(() => remote.createRelationship(any(), any()));
    });
  });

  group('deleteRelationship (pure optimistic path)', () {
    test('queues a delete via the outbox and returns immediately with no remote call', () async {
      final result = await repository.deleteRelationship(personId: 10, relationshipId: 1);

      expect(result, const Right(unit));
      verify(() => local.queueDeletedPersonRelationship(1, payloadJson: any(named: 'payloadJson'))).called(1);
      verifyNever(() => remote.deleteRelationship(any(), any()));
    });
  });

  group('refreshRelationships (permanent full-refetch-as-delta)', () {
    test('applies the fetched snapshot', () async {
      when(() => remote.getAllMinePersonRelationships()).thenAnswer(
        (_) async => const Right([
          PersonRelationshipResponse(id: 1, personId: 10, relatedPersonId: 20, relatedPersonName: 'Ahmed', relationType: RelationType.father),
        ]),
      );

      final result = await repository.refreshRelationships();

      expect(result, const Right(unit));
      final captured = verify(() => local.applyPersonRelationshipsSnapshot(captureAny())).captured;
      expect((captured.single as List<PersonRelationship>).map((r) => r.id), [1]);
    });

    test('propagates a failure unchanged', () async {
      const failure = NetworkFailure();
      when(() => remote.getAllMinePersonRelationships()).thenAnswer((_) async => const Left(failure));

      final result = await repository.refreshRelationships();

      expect(result, const Left(failure));
      verifyNever(() => local.applyPersonRelationshipsSnapshot(any()));
    });
  });
}

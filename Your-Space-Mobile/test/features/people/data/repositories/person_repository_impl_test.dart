import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import 'package:your_space_mobile/features/people/data/datasources/person_local_data_source_impl.dart';
import 'package:your_space_mobile/features/people/data/datasources/person_remote_data_source_impl.dart';
import 'package:your_space_mobile/features/people/data/models/add_occasion_history_request.dart';
import 'package:your_space_mobile/features/people/data/models/create_person_request.dart';
import 'package:your_space_mobile/features/people/data/models/person_details_response.dart';
import 'package:your_space_mobile/features/people/data/models/person_occasion_history_response.dart';
import 'package:your_space_mobile/features/people/data/models/person_response.dart';
import 'package:your_space_mobile/features/people/data/models/update_person_request.dart';
import 'package:your_space_mobile/features/people/data/repositories/person_repository_impl.dart';

class MockPersonRemoteDataSourceImpl extends Mock implements PersonRemoteDataSourceImpl {}

class MockPersonLocalDataSourceImpl extends Mock implements PersonLocalDataSourceImpl {}

class MockSyncService extends Mock implements SyncService {}

const _person = Person(
  id: 10,
  name: 'New Person',
  gender: Gender.male,
  groupId: 1,
  groupName: 'Family',
  governorateId: 1,
  governorateName: 'Cairo',
);

void main() {
  late MockPersonRemoteDataSourceImpl remote;
  late MockPersonLocalDataSourceImpl local;
  late MockSyncService syncService;
  late PersonRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const CreatePersonRequest(name: '', gender: Gender.male, groupId: 0, governorateId: 0),
    );
    registerFallbackValue(
      const UpdatePersonRequest(id: 0, name: '', gender: Gender.male, groupId: 0, governorateId: 0),
    );
    registerFallbackValue(const AddOccasionHistoryRequest(invitedMe: false));
    registerFallbackValue(_person);
    registerFallbackValue(const <Person>[]);
  });

  setUp(() {
    remote = MockPersonRemoteDataSourceImpl();
    local = MockPersonLocalDataSourceImpl();
    syncService = MockSyncService();
    repository = PersonRepositoryImpl(remote, local, syncService);
    when(() => local.savePerson(any())).thenAnswer((_) async {});
    when(() => local.savePersons(any())).thenAnswer((_) async {});
    when(() => local.applyPersonsSnapshot(any())).thenAnswer((_) async {});
    when(
      () => local.queuePersonMutation(
        person: any(named: 'person'),
        operation: any(named: 'operation'),
        payloadJson: any(named: 'payloadJson'),
      ),
    ).thenAnswer((_) async => 99);
  });

  test('getPersonById maps embedded occasion history alongside the person', () async {
    when(() => remote.getPersonById(1)).thenAnswer(
      (_) async => Right(PersonDetailsResponse(
        id: 1,
        name: 'Sara Adel',
        gender: Gender.female,
        groupId: 1,
        groupName: 'Family',
        governorateId: 1,
        governorateName: 'Cairo',
        hasReciprocityHistory: false,
        occasionHistory: const [],
        relationships: const [],
        createdAt: DateTime(2026),
      )),
    );

    final result = await repository.getPersonById(1);

    expect(result.isRight(), isTrue);
    final details = result.getOrElse(() => throw StateError('expected Right'));
    expect(
      details.person,
      const Person(
        id: 1,
        name: 'Sara Adel',
        gender: Gender.female,
        groupId: 1,
        groupName: 'Family',
        governorateId: 1,
        governorateName: 'Cairo',
      ),
    );
    expect(details.occasionHistory, isEmpty);
  });

  test('getPersonById propagates a failure unchanged', () async {
    const failure = ServerFailure(statusCode: 404, message: 'Not found', errorCode: 'Person.NotFound');
    when(() => remote.getPersonById(999)).thenAnswer((_) async => const Left(failure));

    final result = await repository.getPersonById(999);

    expect(result, const Left(failure));
  });

  test('watchPersons delegates straight to the local data source', () {
    when(
      () => local.watchPersons(
        groupId: 1,
        subGroupId: null,
        governorateId: null,
        cityId: null,
        neighborhoodId: null,
        search: 'sara',
        limit: 20,
      ),
    ).thenAnswer((_) => Stream.value([_person]));

    final stream = repository.watchPersons(groupId: 1, search: 'sara', limit: 20);

    expect(stream, emits([_person]));
  });

  test('countPersons delegates straight to the local data source', () async {
    when(
      () => local.countPersons(
        groupId: 1,
        subGroupId: null,
        governorateId: null,
        cityId: null,
        neighborhoodId: null,
        search: null,
      ),
    ).thenAnswer((_) async => 42);

    final count = await repository.countPersons(groupId: 1);

    expect(count, 42);
  });

  group('refreshPersons', () {
    test('loops every remote page and upserts the concatenated, mapped entities', () async {
      when(() => remote.getPersons(pageIndex: 1, pageSize: 100)).thenAnswer(
        (_) async => Right(PaginatedResponse(items: [_toResponse(1)], pageIndex: 1, totalPages: 2, totalItems: 2)),
      );
      when(() => remote.getPersons(pageIndex: 2, pageSize: 100)).thenAnswer(
        (_) async => Right(PaginatedResponse(items: [_toResponse(2)], pageIndex: 2, totalPages: 2, totalItems: 2)),
      );

      final result = await repository.refreshPersons();

      expect(result, const Right(unit));
      final captured = verify(() => local.applyPersonsSnapshot(captureAny())).captured.single as List<Person>;
      expect(captured.map((p) => p.id), [1, 2]);
    });

    test('stops and returns Left immediately on a failing page, without saving anything', () async {
      const failure = NetworkFailure();
      when(() => remote.getPersons(pageIndex: 1, pageSize: 100)).thenAnswer((_) async => const Left(failure));

      final result = await repository.refreshPersons();

      expect(result, const Left(failure));
      verifyNever(() => local.applyPersonsSnapshot(any()));
    });
  });

  group('createPerson (pure optimistic path)', () {
    test('queues a negative-id create via the outbox and returns immediately', () async {
      final result = await repository.createPerson(
        name: 'New Person',
        gender: Gender.male,
        groupId: 1,
        groupName: 'Family',
        governorateId: 1,
        governorateName: 'Cairo',
      );

      expect(result.isRight(), isTrue);
      final person = result.getOrElse(() => throw StateError('expected Right'));
      expect(person.id, lessThan(0));
      expect(person.name, 'New Person');

      final captured = verify(
        () => local.queuePersonMutation(
          person: captureAny(named: 'person'),
          operation: captureAny(named: 'operation'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      expect((captured[0] as Person).id, lessThan(0));
      expect(captured[1], 'create');
      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['name'], 'New Person');
      expect(payload.containsKey('id'), isFalse);

      verifyNever(() => remote.createPerson(any()));
      verifyNever(() => syncService.replayRow(any()));
    });
  });

  group('updatePerson (pure optimistic path)', () {
    test('queues an update against the given id via the outbox and returns immediately', () async {
      final result = await repository.updatePerson(
        id: 42,
        name: 'Renamed',
        gender: Gender.male,
        groupId: 1,
        groupName: 'Family',
        governorateId: 1,
        governorateName: 'Cairo',
      );

      expect(result, isA<Right<Failure, Person>>());
      final captured = verify(
        () => local.queuePersonMutation(
          person: captureAny(named: 'person'),
          operation: captureAny(named: 'operation'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      expect((captured[0] as Person).id, 42);
      expect(captured[1], 'update');
      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['id'], 42);

      verifyNever(() => remote.updatePerson(any()));
      verifyNever(() => syncService.replayRow(any()));
    });
  });

  group('createPersonAndSync', () {
    test('queues via the outbox then returns the real person on a successful immediate replay', () async {
      const realPerson = Person(
        id: 10,
        name: 'New Person',
        gender: Gender.male,
        groupId: 1,
        groupName: 'Family',
        governorateId: 1,
        governorateName: 'Cairo',
      );
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Right(realPerson));

      final result = await repository.createPersonAndSync(
        name: 'New Person',
        gender: Gender.male,
        groupId: 1,
        groupName: 'Family',
        governorateId: 1,
        governorateName: 'Cairo',
      );

      expect(result, const Right(realPerson));
      verify(() => syncService.replayRow(99)).called(1);
    });

    test('the queued row is not rolled back when the immediate replay fails', () async {
      const failure = NetworkFailure();
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Left(failure));

      final result = await repository.createPersonAndSync(
        name: 'New Person',
        gender: Gender.male,
        groupId: 1,
        groupName: 'Family',
        governorateId: 1,
        governorateName: 'Cairo',
      );

      expect(result, const Left(failure));
      // The queue call already happened before the replay attempt — no
      // "undo" method exists or is called.
      verify(
        () => local.queuePersonMutation(
          person: any(named: 'person'),
          operation: 'create',
          payloadJson: any(named: 'payloadJson'),
        ),
      ).called(1);
    });
  });

  group('updatePersonAndSync', () {
    test('queues via the outbox then returns the real person on a successful immediate replay', () async {
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Right(_person));

      final result = await repository.updatePersonAndSync(
        id: 10,
        name: 'New Person',
        gender: Gender.male,
        groupId: 1,
        groupName: 'Family',
        governorateId: 1,
        governorateName: 'Cairo',
      );

      expect(result, const Right(_person));
    });

    test('propagates the failure when the immediate replay fails', () async {
      const failure = ServerFailure(statusCode: 500, message: 'boom');
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Left(failure));

      final result = await repository.updatePersonAndSync(
        id: 10,
        name: 'New Person',
        gender: Gender.male,
        groupId: 1,
        groupName: 'Family',
        governorateId: 1,
        governorateName: 'Cairo',
      );

      expect(result, const Left(failure));
    });
  });

  test('addOccasionHistory maps the response to an entity', () async {
    when(() => remote.addOccasionHistory(any(), any())).thenAnswer(
      (_) async => Right(PersonOccasionHistoryResponse(
        id: 1,
        personId: 1,
        invitedMe: true,
        createdAt: DateTime(2026),
      )),
    );

    final result = await repository.addOccasionHistory(personId: 1, invitedMe: true);

    expect(result.isRight(), isTrue);
    final entry = result.getOrElse(() => throw StateError('expected Right'));
    expect(entry.invitedMe, isTrue);
  });
}

PersonResponse _toResponse(int id) => PersonResponse(
      id: id,
      name: 'Person $id',
      gender: Gender.male,
      groupId: 1,
      groupName: 'Family',
      governorateId: 1,
      governorateName: 'Cairo',
      hasReciprocityHistory: false,
    );

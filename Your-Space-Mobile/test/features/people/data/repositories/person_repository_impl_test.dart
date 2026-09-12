import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
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
    repository = PersonRepositoryImpl(remote, local);
    when(() => local.savePerson(any())).thenAnswer((_) async {});
    when(() => local.savePersons(any())).thenAnswer((_) async {});
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
      final captured = verify(() => local.savePersons(captureAny())).captured.single as List<Person>;
      expect(captured.map((p) => p.id), [1, 2]);
    });

    test('stops and returns Left immediately on a failing page, without saving anything', () async {
      const failure = NetworkFailure();
      when(() => remote.getPersons(pageIndex: 1, pageSize: 100)).thenAnswer((_) async => const Left(failure));

      final result = await repository.refreshPersons();

      expect(result, const Left(failure));
      verifyNever(() => local.savePersons(any()));
    });
  });

  group('createPerson', () {
    test('upserts into the local store and returns the mapped entity on success', () async {
      when(() => remote.createPerson(any())).thenAnswer((_) async => const Right(PersonResponse(
            id: 10,
            name: 'New Person',
            gender: Gender.male,
            groupId: 1,
            groupName: 'Family',
            governorateId: 1,
            governorateName: 'Cairo',
            hasReciprocityHistory: false,
          )));

      final result = await repository.createPerson(
        name: 'New Person',
        gender: Gender.male,
        groupId: 1,
        governorateId: 1,
      );

      expect(result, const Right(_person));
      verify(() => local.savePerson(_person)).called(1);
    });

    test('never touches the local store on failure', () async {
      const failure = ServerFailure(statusCode: 400, message: 'Invalid');
      when(() => remote.createPerson(any())).thenAnswer((_) async => const Left(failure));

      final result = await repository.createPerson(
        name: 'New Person',
        gender: Gender.male,
        groupId: 1,
        governorateId: 1,
      );

      expect(result, const Left(failure));
      verifyNever(() => local.savePerson(any()));
    });
  });

  test('updatePerson upserts into the local store on success', () async {
    when(() => remote.updatePerson(any())).thenAnswer((_) async => const Right(PersonResponse(
          id: 10,
          name: 'New Person',
          gender: Gender.male,
          groupId: 1,
          groupName: 'Family',
          governorateId: 1,
          governorateName: 'Cairo',
          hasReciprocityHistory: false,
        )));

    final result = await repository.updatePerson(
      id: 10,
      name: 'New Person',
      gender: Gender.male,
      groupId: 1,
      governorateId: 1,
    );

    expect(result, const Right(_person));
    verify(() => local.savePerson(_person)).called(1);
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

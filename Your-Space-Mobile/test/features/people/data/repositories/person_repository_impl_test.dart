import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/people/data/datasources/person_remote_data_source_impl.dart';
import 'package:your_space_mobile/features/people/data/models/add_occasion_history_request.dart';
import 'package:your_space_mobile/features/people/data/models/create_person_request.dart';
import 'package:your_space_mobile/features/people/data/models/person_details_response.dart';
import 'package:your_space_mobile/features/people/data/models/person_occasion_history_response.dart';
import 'package:your_space_mobile/features/people/data/models/person_response.dart';
import 'package:your_space_mobile/features/people/data/models/update_person_request.dart';
import 'package:your_space_mobile/features/people/data/repositories/person_repository_impl.dart';

class MockPersonRemoteDataSourceImpl extends Mock implements PersonRemoteDataSourceImpl {}

void main() {
  late MockPersonRemoteDataSourceImpl remote;
  late PersonRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const CreatePersonRequest(name: '', groupId: 0));
    registerFallbackValue(const UpdatePersonRequest(id: 0, name: '', groupId: 0));
    registerFallbackValue(const AddOccasionHistoryRequest(invitedMe: false));
  });

  setUp(() {
    remote = MockPersonRemoteDataSourceImpl();
    repository = PersonRepositoryImpl(remote);
  });

  test('getPersonById maps embedded occasion history alongside the person', () async {
    when(() => remote.getPersonById(1)).thenAnswer(
      (_) async => const Right(PersonDetailsResponse(
        id: 1,
        name: 'Sara Adel',
        groupId: 1,
        groupName: 'Family',
        hasReciprocityHistory: false,
        occasionHistory: [],
      )),
    );

    final result = await repository.getPersonById(1);

    expect(result.isRight(), isTrue);
    final details = result.getOrElse(() => throw StateError('expected Right'));
    expect(details.person, const Person(id: 1, name: 'Sara Adel', groupId: 1, groupName: 'Family'));
    expect(details.occasionHistory, isEmpty);
  });

  test('getPersonById propagates a failure unchanged', () async {
    const failure = ServerFailure(statusCode: 404, message: 'Not found', errorCode: 'Person.NotFound');
    when(() => remote.getPersonById(999)).thenAnswer((_) async => const Left(failure));

    final result = await repository.getPersonById(999);

    expect(result, const Left(failure));
  });

  test('createPerson maps the response to an entity', () async {
    when(() => remote.createPerson(any())).thenAnswer(
      (_) async => const Right(PersonResponse(
        id: 10,
        name: 'New Person',
        groupId: 1,
        groupName: 'Family',
        hasReciprocityHistory: false,
      )),
    );

    final result = await repository.createPerson(name: 'New Person', groupId: 1);

    expect(result, const Right(Person(id: 10, name: 'New Person', groupId: 1, groupName: 'Family')));
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

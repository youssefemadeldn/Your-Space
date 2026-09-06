import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/people/domain/entities/person_details.dart';
import 'package:your_space_mobile/features/people/domain/entities/person_occasion_history_entry.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_details_cubit/person_details_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_details_cubit/person_details_state.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

void main() {
  late MockPersonRepository repository;
  late DataRefreshBus dataRefreshBus;
  late PersonDetailsCubit cubit;

  setUp(() {
    repository = MockPersonRepository();
    dataRefreshBus = DataRefreshBus();
    cubit = PersonDetailsCubit(repository, dataRefreshBus);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with the person and their occasion history', () async {
    const person = Person(
        id: 1,
        name: 'Sara Adel',
        gender: Gender.female,
        groupId: 1,
        groupName: 'Family',
        governorateId: 1,
        governorateName: 'Cairo',
        hasReciprocityHistory: true);
    final details = PersonDetails(
      person: person,
      occasionHistory: [
        PersonOccasionHistoryEntry(id: 1, personId: 1, invitedMe: true, createdAt: DateTime(2026)),
      ],
      relationships: const [],
      createdAt: DateTime(2026),
    );
    when(() => repository.getPersonById(1)).thenAnswer((_) async => Right(details));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const PersonDetailsLoading(),
        isA<PersonDetailsSuccess>()
            .having((s) => s.person.id, 'person.id', 1)
            .having((s) => s.occasions, 'occasions', isNotEmpty),
      ]),
    );

    unawaited(cubit.loadDetails(1));
    await expectation;
  });

  test('emits an Error when the person id does not exist', () async {
    when(() => repository.getPersonById(999999)).thenAnswer(
      (_) async => const Left(
        ServerFailure(statusCode: 404, message: 'Person not found', errorCode: 'Person.NotFound'),
      ),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const PersonDetailsLoading(), isA<PersonDetailsError>()]),
    );

    unawaited(cubit.loadDetails(999999));
    await expectation;
  });

  group('DataRefreshBus', () {
    // Bonus fix: PersonDetailsScreen stays alive underneath when the user
    // taps "edit" (pushes PersonForm) and pops back — same root cause as the
    // tab-level bug, one level deeper in the navigation stack.
    const person = Person(
      id: 1,
      name: 'Sara Adel',
      gender: Gender.female,
      groupId: 1,
      groupName: 'Family',
      governorateId: 1,
      governorateName: 'Cairo',
    );
    final details = PersonDetails(
      person: person,
      occasionHistory: const [],
      relationships: const [],
      createdAt: DateTime(2026),
    );

    Future<void> loadSuccessfully() async {
      when(() => repository.getPersonById(1)).thenAnswer((_) async => Right(details));
      await cubit.loadDetails(1);
    }

    test('a `people` notification re-fetches this same person, no Loading flash', () async {
      await loadSuccessfully();

      const renamed = Person(
        id: 1,
        name: 'Sara Ali',
        gender: Gender.female,
        groupId: 1,
        groupName: 'Family',
        governorateId: 1,
        governorateName: 'Cairo',
      );
      final updatedDetails = PersonDetails(
        person: renamed,
        occasionHistory: const [],
        relationships: const [],
        createdAt: DateTime(2026),
      );
      when(() => repository.getPersonById(1)).thenAnswer((_) async => Right(updatedDetails));

      final states = <dynamic>[];
      final sub = cubit.stream.listen(states.add);

      dataRefreshBus.notify(DataScope.people);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(states, isNot(contains(isA<PersonDetailsLoading>())));
      expect(cubit.state, isA<PersonDetailsSuccess>().having((s) => s.person.name, 'person.name', 'Sara Ali'));
    });

    test('a failed background refresh keeps the last-good details on screen', () async {
      await loadSuccessfully();
      final beforeRefresh = cubit.state;

      when(() => repository.getPersonById(1)).thenAnswer((_) async => const Left(NetworkFailure()));

      dataRefreshBus.notify(DataScope.people);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, beforeRefresh);
    });

    test('is ignored before any details have loaded', () async {
      dataRefreshBus.notify(DataScope.people);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<PersonDetailsInitial>());
      verifyNever(() => repository.getPersonById(any()));
    });
  });
}

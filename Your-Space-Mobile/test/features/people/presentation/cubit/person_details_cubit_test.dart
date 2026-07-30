import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/people/domain/entities/person_details.dart';
import 'package:your_space_mobile/features/people/domain/entities/person_occasion_history_entry.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_details_cubit/person_details_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_details_cubit/person_details_state.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

void main() {
  late MockPersonRepository repository;
  late PersonDetailsCubit cubit;

  setUp(() {
    repository = MockPersonRepository();
    cubit = PersonDetailsCubit(repository);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with the person and their occasion history', () async {
    const person = Person(id: 1, name: 'Sara Adel', groupId: 1, groupName: 'Family', hasReciprocityHistory: true);
    final details = PersonDetails(
      person: person,
      occasionHistory: [
        PersonOccasionHistoryEntry(id: 1, personId: 1, invitedMe: true, createdAt: DateTime(2026)),
      ],
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
}

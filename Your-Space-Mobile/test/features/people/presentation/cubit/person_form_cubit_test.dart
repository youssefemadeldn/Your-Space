import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/people/domain/entities/person_details.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_form_cubit/person_form_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_form_cubit/person_form_state.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockPersonRepository personRepository;
  late MockGroupRepository groupRepository;
  late PersonFormCubit cubit;

  const family = Group(id: 1, name: 'Family');
  const existingPerson =
      Person(id: 7, name: 'Sara Adel', groupId: 1, groupName: 'Family', hasReciprocityHistory: false);

  setUp(() {
    personRepository = MockPersonRepository();
    groupRepository = MockGroupRepository();
    cubit = PersonFormCubit(personRepository, groupRepository);

    when(() => groupRepository.getGroups(pageIndex: 1, pageSize: 50))
        .thenAnswer((_) async => const Right(PaginatedResult(items: [family], pageIndex: 1, totalPages: 1, totalItems: 1)));
  });

  tearDown(() => cubit.close());

  test('initialize(null) emits [Loading, Ready] with person null (create mode)', () async {
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const PersonFormLoading(),
        isA<PersonFormReady>()
            .having((s) => s.person, 'person', isNull)
            .having((s) => s.availableGroups, 'availableGroups', isNotEmpty),
      ]),
    );

    unawaited(cubit.initialize(null));
    await expectation;
  });

  test('initialize(id) emits [Loading, Ready] pre-filled with that person (edit mode)', () async {
    when(() => personRepository.getPersonById(7)).thenAnswer(
      (_) async => Right(PersonDetails(person: existingPerson, occasionHistory: const [])),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const PersonFormLoading(),
        isA<PersonFormReady>().having((s) => s.person?.id, 'person.id', 7),
      ]),
    );

    unawaited(cubit.initialize(7));
    await expectation;
  });

  test('submit with no personId creates a new person', () async {
    when(() => personRepository.createPerson(
          name: any(named: 'name'),
          phoneNumber: any(named: 'phoneNumber'),
          groupId: any(named: 'groupId'),
        )).thenAnswer((_) async => const Right(Person(id: 10, name: 'New Person', groupId: 1, groupName: 'Family')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const PersonFormSubmitting(),
        isA<PersonFormSuccess>().having((s) => s.person.name, 'person.name', 'New Person'),
      ]),
    );

    unawaited(cubit.submit(name: 'New Person', groupId: 1));
    await expectation;
  });

  test('submit with a personId updates the existing person', () async {
    when(() => personRepository.updatePerson(
          id: any(named: 'id'),
          name: any(named: 'name'),
          phoneNumber: any(named: 'phoneNumber'),
          groupId: any(named: 'groupId'),
        )).thenAnswer((_) async => const Right(Person(id: 7, name: 'Renamed', groupId: 1, groupName: 'Family')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const PersonFormSubmitting(),
        isA<PersonFormSuccess>().having((s) => s.person.name, 'person.name', 'Renamed'),
      ]),
    );

    unawaited(cubit.submit(personId: 7, name: 'Renamed', groupId: 1));
    await expectation;
  });
}

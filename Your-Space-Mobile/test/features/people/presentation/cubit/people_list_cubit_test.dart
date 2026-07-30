import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/people_list_cubit/people_list_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/people_list_cubit/people_list_state.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockPersonRepository personRepository;
  late MockGroupRepository groupRepository;
  late PeopleListCubit cubit;

  const family = Group(id: 1, name: 'Family');
  const closeFriends = Group(id: 2, name: 'Close friends');
  const person1 = Person(id: 1, name: 'Sara Adel', groupId: 1, groupName: 'Family');
  const person2 = Person(id: 2, name: 'Omar Khaled', groupId: 2, groupName: 'Close friends');

  setUp(() {
    personRepository = MockPersonRepository();
    groupRepository = MockGroupRepository();
    cubit = PeopleListCubit(personRepository, groupRepository);

    when(() => groupRepository.getGroups(pageIndex: 1, pageSize: 50)).thenAnswer(
      (_) async =>
          const Right(PaginatedResult(items: [family, closeFriends], pageIndex: 1, totalPages: 1, totalItems: 2)),
    );
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with people and groups on load', () async {
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async =>
          const Right(PaginatedResult(items: [person1, person2], pageIndex: 1, totalPages: 1, totalItems: 2)),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const PeopleListLoading(),
        isA<PeopleListSuccess>()
            .having((s) => s.people.length, 'people.length', 2)
            .having((s) => s.groups.length, 'groups.length', 2),
      ]),
    );

    unawaited(cubit.load());
    await expectation;
  });

  test('filterByGroup narrows the list and tracks selectedGroupId', () async {
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async =>
          const Right(PaginatedResult(items: [person1, person2], pageIndex: 1, totalPages: 1, totalItems: 2)),
    );
    await cubit.load();

    when(() => personRepository.getPersons(groupId: family.id, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [person1], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );

    await cubit.filterByGroup(family.id);

    final state = cubit.state as PeopleListSuccess;
    expect(state.selectedGroupId, family.id);
    expect(state.people, [person1]);
  });

  test('loadMore appends the next page', () async {
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [person1], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load();

    when(() => personRepository.getPersons(groupId: null, search: null, pageIndex: 2, pageSize: 20))
        .thenAnswer(
      (_) async => const Right(PaginatedResult(items: [person2], pageIndex: 2, totalPages: 2, totalItems: 2)),
    );

    await cubit.loadMore();

    final state = cubit.state as PeopleListSuccess;
    expect(state.people, [person1, person2]);
    expect(state.hasNextPage, isFalse);
  });
}

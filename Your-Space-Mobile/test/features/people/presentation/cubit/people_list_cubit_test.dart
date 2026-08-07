import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/people_list_cubit/people_list_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/people_list_cubit/people_list_state.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockPersonRepository personRepository;
  late MockGroupRepository groupRepository;
  late DataRefreshBus dataRefreshBus;
  late PeopleListCubit cubit;

  const family = Group(id: 1, name: 'Family');
  const closeFriends = Group(id: 2, name: 'Close friends');
  const person1 = Person(id: 1, name: 'Sara Adel', gender: Gender.female, groupId: 1, groupName: 'Family');
  const person2 =
      Person(id: 2, name: 'Omar Khaled', gender: Gender.male, groupId: 2, groupName: 'Close friends');

  setUp(() {
    personRepository = MockPersonRepository();
    groupRepository = MockGroupRepository();
    dataRefreshBus = DataRefreshBus();
    cubit = PeopleListCubit(personRepository, groupRepository, dataRefreshBus);

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

  test('loadMore appends the next page and advances pageIndex', () async {
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
    expect(state.pageIndex, 2);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [person1], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );
    await cubit.load();

    await cubit.loadMore();

    verifyNever(() => personRepository.getPersons(
          groupId: any(named: 'groupId'),
          search: any(named: 'search'),
          pageIndex: 2,
          pageSize: any(named: 'pageSize'),
        ));
  });

  test('loadMore ignores a second concurrent call while the first is in flight', () async {
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [person1], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load();

    final completer = Completer<Either<Failure, PaginatedResult<Person>>>();
    when(() => personRepository.getPersons(groupId: null, search: null, pageIndex: 2, pageSize: 20))
        .thenAnswer((_) => completer.future);

    final first = cubit.loadMore();
    final second = cubit.loadMore();
    completer.complete(
      const Right(PaginatedResult(items: [person2], pageIndex: 2, totalPages: 2, totalItems: 2)),
    );
    await first;
    await second;

    verify(() => personRepository.getPersons(groupId: null, search: null, pageIndex: 2, pageSize: 20)).called(1);
  });

  test('loadMore preserves existing items and resets isLoadingMore on failure', () async {
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [person1], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load();

    when(() => personRepository.getPersons(groupId: null, search: null, pageIndex: 2, pageSize: 20))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    await cubit.loadMore();

    final state = cubit.state as PeopleListSuccess;
    expect(state.people, [person1]);
    expect(state.pageIndex, 1);
    expect(state.hasNextPage, isTrue);
    expect(state.isLoadingMore, isFalse);
    expect(state.loadMoreErrorMessage, isNotNull);
    expect(state.loadMoreErrorId, 1);
  });

  group('DataRefreshBus', () {
    // Reproduces the original bug: PeopleListCubit is a shell-branch cubit,
    // built once by IndexedStack and never rebuilt — a person added via the
    // sibling PersonForm route never reached it until logout/login. A bus
    // notification must now silently pull the updated list in.
    test('a `people` notification re-fetches page 1 preserving filter/search, no Loading flash', () async {
      when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
        (_) async =>
            const Right(PaginatedResult(items: [person1, person2], pageIndex: 1, totalPages: 1, totalItems: 2)),
      );
      await cubit.load();

      const newPerson =
          Person(id: 3, name: 'Laila Fathy', gender: Gender.female, groupId: 1, groupName: 'Family');
      when(() => personRepository.getPersons(groupId: null, search: null, pageIndex: 1, pageSize: 20)).thenAnswer(
        (_) async => const Right(
          PaginatedResult(items: [person1, person2, newPerson], pageIndex: 1, totalPages: 1, totalItems: 3),
        ),
      );

      final states = <dynamic>[];
      final sub = cubit.stream.listen(states.add);

      dataRefreshBus.notify(DataScope.people);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(states, isNot(contains(isA<PeopleListLoading>())));
      expect(cubit.state, isA<PeopleListSuccess>().having((s) => s.people, 'people', [person1, person2, newPerson]));
    });

    test('a `groups` notification refreshes only the group dropdown, leaving the people page untouched', () async {
      when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
        (_) async =>
            const Right(PaginatedResult(items: [person1, person2], pageIndex: 1, totalPages: 1, totalItems: 2)),
      );
      await cubit.load();

      const newGroup = Group(id: 3, name: 'Book club');
      when(() => groupRepository.getGroups(pageIndex: 1, pageSize: 50)).thenAnswer(
        (_) async => const Right(
          PaginatedResult(items: [family, closeFriends, newGroup], pageIndex: 1, totalPages: 1, totalItems: 3),
        ),
      );

      dataRefreshBus.notify(DataScope.groups);
      await Future<void>.delayed(Duration.zero);

      final state = cubit.state as PeopleListSuccess;
      expect(state.groups, [family, closeFriends, newGroup]);
      expect(state.people, [person1, person2]);
    });

    test('a failed background refresh keeps the last-good list on screen', () async {
      when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
        (_) async =>
            const Right(PaginatedResult(items: [person1, person2], pageIndex: 1, totalPages: 1, totalItems: 2)),
      );
      await cubit.load();
      final beforeRefresh = cubit.state;

      when(() => personRepository.getPersons(groupId: null, search: null, pageIndex: 1, pageSize: 20))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      dataRefreshBus.notify(DataScope.people);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, beforeRefresh);
    });
  });
}

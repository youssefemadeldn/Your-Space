import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_governorate_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/people_list_cubit/people_list_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/people_list_cubit/people_list_state.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockSubGroupRepository extends Mock implements SubGroupRepository {}

class MockGovernorateRepository extends Mock implements GovernorateRepository {}

class MockCityRepository extends Mock implements CityRepository {}

class MockNeighborhoodRepository extends Mock implements NeighborhoodRepository {}

void main() {
  late MockPersonRepository personRepository;
  late MockGroupRepository groupRepository;
  late MockSubGroupRepository subGroupRepository;
  late MockGovernorateRepository governorateRepository;
  late MockCityRepository cityRepository;
  late MockNeighborhoodRepository neighborhoodRepository;
  late DataRefreshBus dataRefreshBus;
  late PeopleListCubit cubit;

  const family = Group(id: 1, name: 'Family');
  const closeFriends = Group(id: 2, name: 'Close friends');
  const person1 = Person(
    id: 1,
    name: 'Sara Adel',
    gender: Gender.female,
    groupId: 1,
    groupName: 'Family',
    governorateId: 1,
    governorateName: 'Cairo',
  );
  const person2 = Person(
    id: 2,
    name: 'Omar Khaled',
    gender: Gender.male,
    groupId: 2,
    groupName: 'Close friends',
    governorateId: 1,
    governorateName: 'Cairo',
  );

  /// Stubs a `watchPersons`/`countPersons` pair for a full set of filter
  /// values (defaults match `PeopleListCubit`'s "no filters" call shape).
  void stubPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
    required int limit,
    required List<Person> people,
    required int total,
  }) {
    when(
      () => personRepository.watchPersons(
        groupId: groupId,
        subGroupId: subGroupId,
        governorateId: governorateId,
        cityId: cityId,
        neighborhoodId: neighborhoodId,
        search: search,
        limit: limit,
      ),
    ).thenAnswer((_) => Stream.value(people));
    when(
      () => personRepository.countPersons(
        groupId: groupId,
        subGroupId: subGroupId,
        governorateId: governorateId,
        cityId: cityId,
        neighborhoodId: neighborhoodId,
        search: search,
      ),
    ).thenAnswer((_) async => total);
  }

  setUp(() {
    personRepository = MockPersonRepository();
    groupRepository = MockGroupRepository();
    subGroupRepository = MockSubGroupRepository();
    governorateRepository = MockGovernorateRepository();
    cityRepository = MockCityRepository();
    neighborhoodRepository = MockNeighborhoodRepository();
    dataRefreshBus = DataRefreshBus();
    cubit = PeopleListCubit(
      personRepository,
      groupRepository,
      subGroupRepository,
      governorateRepository,
      cityRepository,
      neighborhoodRepository,
      dataRefreshBus,
    );

    when(() => groupRepository.watchGroups(limit: 50)).thenAnswer((_) => Stream.value(const [family, closeFriends]));
    when(() => governorateRepository.watchGovernorates(limit: 50))
        .thenAnswer((_) => Stream.value(const <Governorate>[]));
    when(() => subGroupRepository.watchSubGroups(groupId: family.id, limit: 50))
        .thenAnswer((_) => Stream.value(const <SubGroup>[]));
    when(() => personRepository.refreshPersons()).thenAnswer((_) async => const Right(unit));
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with people and groups on load, and kicks off a background refresh', () async {
    stubPersons(limit: 20, people: const [person1, person2], total: 2);

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const PeopleListLoading(),
        isA<PeopleListSuccess>()
            .having((s) => s.people.length, 'people.length', 2)
            .having((s) => s.groups.length, 'groups.length', 2),
      ]),
    );

    await cubit.load();
    await expectation;

    verify(() => personRepository.refreshPersons()).called(1);
  });

  test('filterByGroup resubscribes with the new filter and resets to the base limit', () async {
    stubPersons(limit: 20, people: const [person1, person2], total: 2);
    await cubit.load();

    stubPersons(groupId: family.id, limit: 20, people: const [person1], total: 1);

    await cubit.filterByGroup(family.id);

    final state = cubit.state as PeopleListSuccess;
    expect(state.selectedGroupId, family.id);
    expect(state.people, [person1]);
    expect(state.limit, 20);
  });

  test('loadMore grows the limit and hasNextPage reflects the exact count', () async {
    stubPersons(limit: 20, people: const [person1], total: 2);
    await cubit.load();
    expect((cubit.state as PeopleListSuccess).hasNextPage, isTrue);

    stubPersons(limit: 40, people: const [person1, person2], total: 2);

    await cubit.loadMore();

    final state = cubit.state as PeopleListSuccess;
    expect(state.people, [person1, person2]);
    expect(state.limit, 40);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    stubPersons(limit: 20, people: const [person1], total: 1);
    await cubit.load();

    await cubit.loadMore();

    verifyNever(
      () => personRepository.watchPersons(
        groupId: any(named: 'groupId'),
        subGroupId: any(named: 'subGroupId'),
        governorateId: any(named: 'governorateId'),
        cityId: any(named: 'cityId'),
        neighborhoodId: any(named: 'neighborhoodId'),
        search: any(named: 'search'),
        limit: 40,
      ),
    );
  });

  test('loadMore ignores a second concurrent call while the first is in flight', () async {
    stubPersons(limit: 20, people: const [person1], total: 2);
    await cubit.load();

    final controller = StreamController<List<Person>>();
    when(
      () => personRepository.watchPersons(
        groupId: null,
        subGroupId: null,
        governorateId: null,
        cityId: null,
        neighborhoodId: null,
        search: null,
        limit: 40,
      ),
    ).thenAnswer((_) => controller.stream);
    when(
      () => personRepository.countPersons(
        groupId: null,
        subGroupId: null,
        governorateId: null,
        cityId: null,
        neighborhoodId: null,
        search: null,
      ),
    ).thenAnswer((_) async => 2);

    final first = cubit.loadMore();
    final second = cubit.loadMore();
    controller.add(const [person1, person2]);
    await controller.close();
    await first;
    await second;

    verify(
      () => personRepository.watchPersons(
        groupId: null,
        subGroupId: null,
        governorateId: null,
        cityId: null,
        neighborhoodId: null,
        search: null,
        limit: 40,
      ),
    ).called(1);
  });

  test('loadMore preserves the existing items/limit and resets isLoadingMore on failure', () async {
    stubPersons(limit: 20, people: const [person1], total: 2);
    await cubit.load();

    when(
      () => personRepository.watchPersons(
        groupId: null,
        subGroupId: null,
        governorateId: null,
        cityId: null,
        neighborhoodId: null,
        search: null,
        limit: 40,
      ),
    ).thenAnswer((_) => Stream.error(Exception('local I/O error')));

    await cubit.loadMore();

    final state = cubit.state as PeopleListSuccess;
    expect(state.people, [person1]);
    expect(state.limit, 20);
    expect(state.hasNextPage, isTrue);
    expect(state.isLoadingMore, isFalse);
    expect(state.loadMoreErrorMessage, isNotNull);
    expect(state.loadMoreErrorId, 1);
  });

  group('DataRefreshBus', () {
    test('a `people` notification no longer triggers anything — the write-path upsert keeps the stream current',
        () async {
      stubPersons(limit: 20, people: const [person1, person2], total: 2);
      await cubit.load();
      clearInteractions(personRepository);

      dataRefreshBus.notify(DataScope.people);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => personRepository.refreshPersons());
      verifyNever(
        () => personRepository.watchPersons(
          groupId: any(named: 'groupId'),
          subGroupId: any(named: 'subGroupId'),
          governorateId: any(named: 'governorateId'),
          cityId: any(named: 'cityId'),
          neighborhoodId: any(named: 'neighborhoodId'),
          search: any(named: 'search'),
          limit: any(named: 'limit'),
        ),
      );
    });

    test('a `groups` notification refreshes only the group dropdown, leaving the people list untouched', () async {
      stubPersons(limit: 20, people: const [person1, person2], total: 2);
      await cubit.load();

      const newGroup = Group(id: 3, name: 'Book club');
      when(() => groupRepository.watchGroups(limit: 50))
          .thenAnswer((_) => Stream.value(const [family, closeFriends, newGroup]));

      dataRefreshBus.notify(DataScope.groups);
      await Future<void>.delayed(Duration.zero);

      final state = cubit.state as PeopleListSuccess;
      expect(state.groups, [family, closeFriends, newGroup]);
      expect(state.people, [person1, person2]);
    });
  });
}

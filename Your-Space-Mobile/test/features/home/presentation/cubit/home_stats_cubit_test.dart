import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:your_space_mobile/features/auth/domain/use_cases/get_current_user_profile_use_case.dart';
import 'package:your_space_mobile/features/events/domain/entities/event.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/home/presentation/cubit/home_stats_cubit/home_stats_cubit.dart';
import 'package:your_space_mobile/features/home/presentation/cubit/home_stats_cubit/home_stats_state.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockPersonRepository extends Mock implements PersonRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockGetCurrentUserProfileUseCase extends Mock implements GetCurrentUserProfileUseCase {}

const _profile = UserProfile(
  id: 'user-1',
  email: 'jane@example.com',
  firstName: 'Jane',
  lastName: 'Doe',
  gender: Gender.female,
  avatarUrl: 'https://example.com/avatar.jpg',
  roles: ['User'],
);

void main() {
  late MockGroupRepository groupRepository;
  late MockPersonRepository personRepository;
  late MockEventRepository eventRepository;
  late MockGetCurrentUserProfileUseCase getCurrentUserProfile;
  late DataRefreshBus dataRefreshBus;
  late HomeStatsCubit cubit;

  setUp(() {
    groupRepository = MockGroupRepository();
    personRepository = MockPersonRepository();
    eventRepository = MockEventRepository();
    getCurrentUserProfile = MockGetCurrentUserProfileUseCase();
    dataRefreshBus = DataRefreshBus();
    when(() => getCurrentUserProfile()).thenAnswer((_) async => const Right(_profile));
    cubit =
        HomeStatsCubit(groupRepository, personRepository, eventRepository, getCurrentUserProfile, dataRefreshBus);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with totalItems from each list endpoint', () async {
    when(() => groupRepository.getGroups(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async =>
          const Right(PaginatedResult(items: [Group(id: 1, name: 'Family')], pageIndex: 1, totalPages: 4, totalItems: 4)),
    );
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async => const Right(PaginatedResult(
        items: [Person(id: 1, name: 'Sara Adel', gender: Gender.female, groupId: 1, groupName: 'Family')],
        pageIndex: 1,
        totalPages: 10,
        totalItems: 10,
      )),
    );
    when(() => eventRepository.getEvents(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async => const Right(
        PaginatedResult(items: [Event(id: 1, name: 'Birthday')], pageIndex: 1, totalPages: 2, totalItems: 2),
      ),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const HomeStatsLoading(),
        isA<HomeStatsSuccess>()
            .having((s) => s.groupsCount, 'groupsCount', 4)
            .having((s) => s.peopleCount, 'peopleCount', 10)
            .having((s) => s.eventsCount, 'eventsCount', 2)
            .having((s) => s.firstName, 'firstName', 'Jane')
            .having((s) => s.avatarUrl, 'avatarUrl', 'https://example.com/avatar.jpg'),
      ]),
    );

    unawaited(cubit.load());
    await expectation;
  });

  test('emits an Error when the profile fetch fails, even if all three counts succeed', () async {
    when(() => groupRepository.getGroups(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 0, totalItems: 0)),
    );
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 0, totalItems: 0)),
    );
    when(() => eventRepository.getEvents(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 0, totalItems: 0)),
    );
    when(() => getCurrentUserProfile()).thenAnswer((_) async => const Left(NetworkFailure()));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const HomeStatsLoading(), isA<HomeStatsError>()]),
    );

    unawaited(cubit.load());
    await expectation;
  });

  group('DataRefreshBus', () {
    Future<void> loadSuccessfully() async {
      when(() => groupRepository.getGroups(pageIndex: 1, pageSize: 1)).thenAnswer(
        (_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 1, totalItems: 1)),
      );
      when(() => personRepository.getPersons(pageIndex: 1, pageSize: 1)).thenAnswer(
        (_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 1, totalItems: 1)),
      );
      when(() => eventRepository.getEvents(pageIndex: 1, pageSize: 1)).thenAnswer(
        (_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 1, totalItems: 1)),
      );
      await cubit.load();
    }

    // Reproduces the original bug: Home's IndexedStack branch cubit is built
    // once and never rebuilt, so a mutation elsewhere (adding a person, etc.)
    // never reached it until logout/login. A DataRefreshBus notification must
    // now silently pull the updated counts in, with no Loading flash.
    test('a bus notification triggers a silent re-fetch, without a Loading flash', () async {
      await loadSuccessfully();

      when(() => personRepository.getPersons(pageIndex: 1, pageSize: 1)).thenAnswer(
        (_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 1, totalItems: 5)),
      );

      final states = <dynamic>[];
      final sub = cubit.stream.listen(states.add);

      dataRefreshBus.notify(DataScope.people);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(states, isNot(contains(isA<HomeStatsLoading>())));
      expect(cubit.state, isA<HomeStatsSuccess>().having((s) => s.peopleCount, 'peopleCount', 5));
    });

    test('a failed background refresh keeps the last-good stats on screen', () async {
      await loadSuccessfully();
      final beforeRefresh = cubit.state;

      when(() => personRepository.getPersons(pageIndex: 1, pageSize: 1))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      dataRefreshBus.notify(DataScope.people);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, beforeRefresh);
    });

    test('is ignored while still in the initial/loading state', () async {
      dataRefreshBus.notify(DataScope.people);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<HomeStatsInitial>());
      verifyNever(() => personRepository.getPersons(pageIndex: any(named: 'pageIndex'), pageSize: any(named: 'pageSize')));
    });
  });

  test('emits an Error when any one of the three calls fails', () async {
    when(() => groupRepository.getGroups(pageIndex: 1, pageSize: 1))
        .thenAnswer((_) async => const Left(NetworkFailure()));
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 0, totalItems: 0)),
    );
    when(() => eventRepository.getEvents(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 0, totalItems: 0)),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const HomeStatsLoading(), isA<HomeStatsError>()]),
    );

    unawaited(cubit.load());
    await expectation;
  });
}

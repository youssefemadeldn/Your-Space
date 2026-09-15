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
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/home/presentation/cubit/home_stats_cubit/home_stats_cubit.dart';
import 'package:your_space_mobile/features/home/presentation/cubit/home_stats_cubit/home_stats_state.dart';
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

  test('emits [Loading, Success] with counts from each source', () async {
    when(() => groupRepository.countGroups()).thenAnswer((_) async => 4);
    when(() => personRepository.countPersons()).thenAnswer((_) async => 10);
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

  // A failed profile fetch on a cold start (e.g. offline) has no prior
  // greeting to fall back to — it degrades to an empty name/avatar rather
  // than discarding the counts that did succeed and blanking the dashboard.
  test('a failed profile fetch on initial load does not blank the dashboard — it falls back to an empty greeting',
      () async {
    when(() => groupRepository.countGroups()).thenAnswer((_) async => 4);
    when(() => personRepository.countPersons()).thenAnswer((_) async => 10);
    when(() => eventRepository.getEvents(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async => const Right(
        PaginatedResult(items: [Event(id: 1, name: 'Birthday')], pageIndex: 1, totalPages: 2, totalItems: 2),
      ),
    );
    when(() => getCurrentUserProfile()).thenAnswer((_) async => const Left(NetworkFailure()));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const HomeStatsLoading(),
        isA<HomeStatsSuccess>()
            .having((s) => s.groupsCount, 'groupsCount', 4)
            .having((s) => s.peopleCount, 'peopleCount', 10)
            .having((s) => s.eventsCount, 'eventsCount', 2)
            .having((s) => s.firstName, 'firstName', '')
            .having((s) => s.avatarUrl, 'avatarUrl', isNull),
      ]),
    );

    unawaited(cubit.load());
    await expectation;
  });

  // Groups/People are local-first (CLAUDE.md Architecture rule 7) — a local
  // count can't fail. Events has no local-first migration yet, so a failed
  // Events fetch folds to 0 instead of blanking the whole dashboard.
  test('a failed Events fetch does not blank the dashboard — it falls back to 0', () async {
    when(() => groupRepository.countGroups()).thenAnswer((_) async => 4);
    when(() => personRepository.countPersons()).thenAnswer((_) async => 10);
    when(() => eventRepository.getEvents(pageIndex: 1, pageSize: 1))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const HomeStatsLoading(),
        isA<HomeStatsSuccess>()
            .having((s) => s.groupsCount, 'groupsCount', 4)
            .having((s) => s.peopleCount, 'peopleCount', 10)
            .having((s) => s.eventsCount, 'eventsCount', 0),
      ]),
    );

    unawaited(cubit.load());
    await expectation;
  });

  group('DataRefreshBus', () {
    Future<void> loadSuccessfully() async {
      when(() => groupRepository.countGroups()).thenAnswer((_) async => 1);
      when(() => personRepository.countPersons()).thenAnswer((_) async => 1);
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

      when(() => personRepository.countPersons()).thenAnswer((_) async => 5);

      final states = <dynamic>[];
      final sub = cubit.stream.listen(states.add);

      dataRefreshBus.notify(DataScope.people);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(states, isNot(contains(isA<HomeStatsLoading>())));
      expect(cubit.state, isA<HomeStatsSuccess>().having((s) => s.peopleCount, 'peopleCount', 5));
    });

    // Unlike the initial `load()`, a refresh has a prior `HomeStatsSuccess`
    // to fall back to: counts are re-fetched fresh, but a failed profile
    // fetch keeps the existing greeting instead of blanking it — so with no
    // other mocked value changed, the resulting state is identical.
    test('a failed background refresh keeps the last-good greeting on screen', () async {
      await loadSuccessfully();
      final beforeRefresh = cubit.state;

      when(() => getCurrentUserProfile()).thenAnswer((_) async => const Left(NetworkFailure()));

      dataRefreshBus.notify(DataScope.people);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, beforeRefresh);
    });

    test('is ignored while still in the initial/loading state', () async {
      dataRefreshBus.notify(DataScope.people);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<HomeStatsInitial>());
      verifyNever(() => personRepository.countPersons());
    });
  });
}

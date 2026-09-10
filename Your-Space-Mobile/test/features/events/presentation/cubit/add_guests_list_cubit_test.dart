import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_governorate_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_progress_summary.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';
import 'package:your_space_mobile/features/events/domain/entities/group_guest_progress.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_list_cubit/add_guests_list_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_list_cubit/add_guests_list_state.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

class MockEventGuestRepository extends Mock implements EventGuestRepository {}

class MockSubGroupRepository extends Mock implements SubGroupRepository {}

class MockGovernorateRepository extends Mock implements GovernorateRepository {}

class MockCityRepository extends Mock implements CityRepository {}

class MockNeighborhoodRepository extends Mock implements NeighborhoodRepository {}

void main() {
  late MockPersonRepository personRepository;
  late MockEventGuestRepository eventGuestRepository;
  late MockSubGroupRepository subGroupRepository;
  late MockGovernorateRepository governorateRepository;
  late MockCityRepository cityRepository;
  late MockNeighborhoodRepository neighborhoodRepository;
  late AddGuestsListCubit cubit;

  const existingGuest = EventGuest(
    id: 1,
    eventId: 1,
    personId: 1,
    personName: 'Sara Adel',
    groupId: 1,
    groupName: 'Family',
    status: EventGuestStatus.notInvited,
  );
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

  const progress = EventGuestProgressSummary(
    eventId: 1,
    totalGuestCount: 1,
    notInvitedCount: 1,
    invitedCount: 0,
    skippedCount: 0,
    groups: [
      GroupGuestProgress(
        groupId: 1,
        groupName: 'Family',
        totalPersonsInGroup: 1,
        guestsAddedCount: 1,
        notInvitedCount: 1,
        invitedCount: 0,
        skippedCount: 0,
      ),
      GroupGuestProgress(
        groupId: 2,
        groupName: 'Close friends',
        totalPersonsInGroup: 1,
        guestsAddedCount: 0,
        notInvitedCount: 0,
        invitedCount: 0,
        skippedCount: 0,
      ),
    ],
  );

  setUp(() {
    personRepository = MockPersonRepository();
    eventGuestRepository = MockEventGuestRepository();
    subGroupRepository = MockSubGroupRepository();
    governorateRepository = MockGovernorateRepository();
    cityRepository = MockCityRepository();
    neighborhoodRepository = MockNeighborhoodRepository();
    cubit = AddGuestsListCubit(
      personRepository,
      eventGuestRepository,
      subGroupRepository,
      governorateRepository,
      cityRepository,
      neighborhoodRepository,
    );

    when(() => eventGuestRepository.getEventGuests(1, pageIndex: 1, pageSize: 50)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [existingGuest], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );
    when(() => eventGuestRepository.getProgress(1)).thenAnswer((_) async => const Right(progress));
    when(() => governorateRepository.getGovernorates(pageIndex: 1, pageSize: 50)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 1, totalItems: 0)),
    );
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] excluding persons already on the guest list', () async {
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async =>
          const Right(PaginatedResult(items: [person1, person2], pageIndex: 1, totalPages: 1, totalItems: 2)),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const AddGuestsListLoading(),
        isA<AddGuestsListSuccess>().having((s) => s.availablePeople, 'availablePeople', [person2]),
      ]),
    );

    unawaited(cubit.load(1));
    await expectation;
  });

  test('availableCountForGroup reads from the progress endpoint, not the paginated people list', () async {
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [person2], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );
    await cubit.load(1);

    final state = cubit.state as AddGuestsListSuccess;
    // Family: 1 total - 1 already added = 0 available.
    expect(state.availableCountForGroup(1), 0);
    // Close friends: 1 total - 0 already added = 1 available.
    expect(state.availableCountForGroup(2), 1);
  });

  test('loadMore appends the next page, still excluding existing guests', () async {
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [person1], pageIndex: 1, totalPages: 2, totalItems: 3)),
    );
    await cubit.load(1);

    when(() => personRepository.getPersons(pageIndex: 2, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [person2], pageIndex: 2, totalPages: 2, totalItems: 3)),
    );

    await cubit.loadMore();

    final state = cubit.state as AddGuestsListSuccess;
    expect(state.availablePeople, [person2]);
    expect(state.pageIndex, 2);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [person2], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );
    await cubit.load(1);

    await cubit.loadMore();

    verifyNever(() => personRepository.getPersons(pageIndex: 2, pageSize: any(named: 'pageSize')));
  });

  test('loadMore ignores a second concurrent call while the first is in flight', () async {
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [person1], pageIndex: 1, totalPages: 2, totalItems: 3)),
    );
    await cubit.load(1);

    final completer = Completer<Either<Failure, PaginatedResult<Person>>>();
    when(() => personRepository.getPersons(pageIndex: 2, pageSize: 20)).thenAnswer((_) => completer.future);

    final first = cubit.loadMore();
    final second = cubit.loadMore();
    completer.complete(
      const Right(PaginatedResult(items: [person2], pageIndex: 2, totalPages: 2, totalItems: 3)),
    );
    await first;
    await second;

    verify(() => personRepository.getPersons(pageIndex: 2, pageSize: 20)).called(1);
  });

  test('loadMore preserves existing items and resets isLoadingMore on failure', () async {
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [person2], pageIndex: 1, totalPages: 2, totalItems: 3)),
    );
    await cubit.load(1);

    when(() => personRepository.getPersons(pageIndex: 2, pageSize: 20))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    await cubit.loadMore();

    final state = cubit.state as AddGuestsListSuccess;
    expect(state.availablePeople, [person2]);
    expect(state.pageIndex, 1);
    expect(state.hasNextPage, isTrue);
    expect(state.isLoadingMore, isFalse);
  });
}

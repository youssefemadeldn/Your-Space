import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
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

    when(() => eventGuestRepository.watchEventGuests(eventId: 1, limit: any(named: 'limit')))
        .thenAnswer((_) => Stream.value(const [existingGuest]));
    when(() => eventGuestRepository.getProgress(1)).thenAnswer((_) async => const Right(progress));
    when(() => governorateRepository.watchGovernorates(limit: 50))
        .thenAnswer((_) => Stream.value(const []));
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] excluding persons already on the guest list', () async {
    when(() => personRepository.watchPersons(limit: 20)).thenAnswer((_) => Stream.value(const [person1, person2]));
    when(() => personRepository.countPersons()).thenAnswer((_) async => 2);

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

  test('availableCountForGroup reads from the progress endpoint, not the local people list', () async {
    when(() => personRepository.watchPersons(limit: 20)).thenAnswer((_) => Stream.value(const [person2]));
    when(() => personRepository.countPersons()).thenAnswer((_) async => 1);
    await cubit.load(1);

    final state = cubit.state as AddGuestsListSuccess;
    // Family: 1 total - 1 already added = 0 available.
    expect(state.availableCountForGroup(1), 0);
    // Close friends: 1 total - 0 already added = 1 available.
    expect(state.availableCountForGroup(2), 1);
  });

  test('loadMore grows the local window, still excluding existing guests', () async {
    when(() => personRepository.watchPersons(limit: 20)).thenAnswer((_) => Stream.value(const [person1]));
    when(() => personRepository.countPersons()).thenAnswer((_) async => 2);
    await cubit.load(1);

    // Local-first: growing the limit re-queries the full window, not a
    // separate "next page" — person1 is still present, plus person2 now
    // falls inside the wider limit.
    when(() => personRepository.watchPersons(limit: 40)).thenAnswer((_) => Stream.value(const [person1, person2]));

    await cubit.loadMore();

    final state = cubit.state as AddGuestsListSuccess;
    expect(state.availablePeople, [person2]);
    expect(state.limit, 40);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    when(() => personRepository.watchPersons(limit: 20)).thenAnswer((_) => Stream.value(const [person2]));
    when(() => personRepository.countPersons()).thenAnswer((_) async => 1);
    await cubit.load(1);

    await cubit.loadMore();

    verifyNever(() => personRepository.watchPersons(limit: 40));
  });

  test('loadMore ignores a second concurrent call while the first is in flight', () async {
    when(() => personRepository.watchPersons(limit: 20)).thenAnswer((_) => Stream.value(const [person1]));
    when(() => personRepository.countPersons()).thenAnswer((_) async => 3);
    await cubit.load(1);

    final controller = StreamController<List<Person>>();
    when(() => personRepository.watchPersons(limit: 40)).thenAnswer((_) => controller.stream);

    final first = cubit.loadMore();
    final second = cubit.loadMore();
    controller.add(const [person1, person2]);
    await first;
    await second;
    await controller.close();

    verify(() => personRepository.watchPersons(limit: 40)).called(1);
  });

  test('loadMore surfaces an error state when the local stream errors', () async {
    when(() => personRepository.watchPersons(limit: 20)).thenAnswer((_) => Stream.value(const [person2]));
    when(() => personRepository.countPersons()).thenAnswer((_) async => 3);
    await cubit.load(1);

    when(() => personRepository.watchPersons(limit: 40)).thenAnswer((_) => Stream.error(const NetworkFailure()));

    await cubit.loadMore();

    expect(cubit.state, isA<AddGuestsListError>());
  });
}

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_guests_list_cubit/event_guests_list_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_guests_list_cubit/event_guests_list_state.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';

class MockEventGuestRepository extends Mock implements EventGuestRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockEventGuestRepository eventGuestRepository;
  late MockGroupRepository groupRepository;
  late EventGuestsListCubit cubit;

  const guest1 = EventGuest(
    id: 1,
    eventId: 1,
    personId: 1,
    personName: 'Sara Adel',
    groupId: 1,
    groupName: 'Family',
    status: EventGuestStatus.notInvited,
  );
  const guest2 = EventGuest(
    id: 2,
    eventId: 1,
    personId: 2,
    personName: 'Omar Khaled',
    groupId: 2,
    groupName: 'Close friends',
    status: EventGuestStatus.invited,
  );

  void stubGuests({
    int eventId = 1,
    int? groupId,
    EventGuestStatus? status,
    required int limit,
    required List<EventGuest> guests,
    required int total,
  }) {
    when(() => eventGuestRepository.watchEventGuests(eventId: eventId, groupId: groupId, status: status, limit: limit))
        .thenAnswer((_) => Stream.value(guests));
    when(() => eventGuestRepository.countEventGuests(eventId: eventId, groupId: groupId, status: status))
        .thenAnswer((_) async => total);
  }

  setUp(() {
    eventGuestRepository = MockEventGuestRepository();
    groupRepository = MockGroupRepository();
    cubit = EventGuestsListCubit(eventGuestRepository, groupRepository);

    when(() => groupRepository.getGroups(pageIndex: 1, pageSize: 50))
        .thenAnswer((_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 1, totalItems: 0)));
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with all guests for the event', () async {
    stubGuests(limit: 20, guests: const [guest1, guest2], total: 2);

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const EventGuestsListLoading(),
        isA<EventGuestsListSuccess>().having((s) => s.guests.length, 'guests.length', 2),
      ]),
    );

    unawaited(cubit.load(1));
    await expectation;
  });

  test('filterByStatus narrows the list and tracks selectedStatus', () async {
    stubGuests(limit: 20, guests: const [guest1, guest2], total: 2);
    await cubit.load(1);

    stubGuests(status: EventGuestStatus.invited, limit: 20, guests: const [guest2], total: 1);

    await cubit.filterByStatus(EventGuestStatus.invited);

    final state = cubit.state as EventGuestsListSuccess;
    expect(state.selectedStatus, EventGuestStatus.invited);
    expect(state.guests, [guest2]);
  });

  test('filterByGroup narrows the list and tracks selectedGroupId', () async {
    stubGuests(limit: 20, guests: const [guest1, guest2], total: 2);
    await cubit.load(1);

    stubGuests(groupId: 2, limit: 20, guests: const [guest2], total: 1);

    await cubit.filterByGroup(2);

    final state = cubit.state as EventGuestsListSuccess;
    expect(state.selectedGroupId, 2);
    expect(state.guests, [guest2]);
  });

  test('loadMore grows the limit and hasNextPage reflects the exact count', () async {
    stubGuests(limit: 20, guests: const [guest1], total: 2);
    await cubit.load(1);
    expect((cubit.state as EventGuestsListSuccess).hasNextPage, isTrue);

    stubGuests(limit: 40, guests: const [guest1, guest2], total: 2);

    await cubit.loadMore();

    final state = cubit.state as EventGuestsListSuccess;
    expect(state.guests, [guest1, guest2]);
    expect(state.limit, 40);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    stubGuests(limit: 20, guests: const [guest1], total: 1);
    await cubit.load(1);

    await cubit.loadMore();

    verifyNever(() => eventGuestRepository.watchEventGuests(
          eventId: 1,
          groupId: any(named: 'groupId'),
          status: any(named: 'status'),
          limit: 40,
        ));
  });

  test('emits [Loading, Error] when the local read throws', () async {
    when(() => eventGuestRepository.watchEventGuests(eventId: 1, groupId: null, status: null, limit: 20))
        .thenAnswer((_) => Stream.error(Exception('boom')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const EventGuestsListLoading(), isA<EventGuestsListError>()]),
    );

    unawaited(cubit.load(1));
    await expectation;
  });
}

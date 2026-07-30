import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
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

  setUp(() {
    eventGuestRepository = MockEventGuestRepository();
    groupRepository = MockGroupRepository();
    cubit = EventGuestsListCubit(eventGuestRepository, groupRepository);

    when(() => groupRepository.getGroups(pageIndex: 1, pageSize: 50))
        .thenAnswer((_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 1, totalItems: 0)));
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with all guests for the event', () async {
    when(() => eventGuestRepository.getEventGuests(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async =>
          const Right(PaginatedResult(items: [guest1, guest2], pageIndex: 1, totalPages: 1, totalItems: 2)),
    );

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
    when(() => eventGuestRepository.getEventGuests(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async =>
          const Right(PaginatedResult(items: [guest1, guest2], pageIndex: 1, totalPages: 1, totalItems: 2)),
    );
    await cubit.load(1);

    when(() => eventGuestRepository.getEventGuests(
          1,
          groupId: null,
          status: EventGuestStatus.invited,
          pageIndex: 1,
          pageSize: 20,
        )).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [guest2], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );

    await cubit.filterByStatus(EventGuestStatus.invited);

    final state = cubit.state as EventGuestsListSuccess;
    expect(state.selectedStatus, EventGuestStatus.invited);
    expect(state.guests, [guest2]);
  });

  test('reloadAfterAction re-queries page 1 without emitting a Loading state', () async {
    when(() => eventGuestRepository.getEventGuests(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [guest1], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );
    await cubit.load(1);

    when(() => eventGuestRepository.getEventGuests(1, groupId: null, status: null, pageIndex: 1, pageSize: 20))
        .thenAnswer(
      (_) async =>
          const Right(PaginatedResult(items: [guest1, guest2], pageIndex: 1, totalPages: 1, totalItems: 2)),
    );

    // emits() matches exactly the next single emission — if reloadAfterAction
    // emitted Loading first, this would fail on that mismatch.
    final expectation = expectLater(cubit.stream, emits(isA<EventGuestsListSuccess>()));
    unawaited(cubit.reloadAfterAction());
    await expectation;
  });

  test('loadMore appends the next page and advances pageIndex', () async {
    when(() => eventGuestRepository.getEventGuests(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [guest1], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load(1);

    when(() => eventGuestRepository.getEventGuests(1, groupId: null, status: null, pageIndex: 2, pageSize: 20))
        .thenAnswer(
      (_) async => const Right(PaginatedResult(items: [guest2], pageIndex: 2, totalPages: 2, totalItems: 2)),
    );

    await cubit.loadMore();

    final state = cubit.state as EventGuestsListSuccess;
    expect(state.guests, [guest1, guest2]);
    expect(state.pageIndex, 2);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    when(() => eventGuestRepository.getEventGuests(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [guest1], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );
    await cubit.load(1);

    await cubit.loadMore();

    verifyNever(() => eventGuestRepository.getEventGuests(
          1,
          groupId: any(named: 'groupId'),
          status: any(named: 'status'),
          pageIndex: 2,
          pageSize: any(named: 'pageSize'),
        ));
  });

  test('loadMore ignores a second concurrent call while the first is in flight', () async {
    when(() => eventGuestRepository.getEventGuests(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [guest1], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load(1);

    final completer = Completer<Either<Failure, PaginatedResult<EventGuest>>>();
    when(() => eventGuestRepository.getEventGuests(1, groupId: null, status: null, pageIndex: 2, pageSize: 20))
        .thenAnswer((_) => completer.future);

    final first = cubit.loadMore();
    final second = cubit.loadMore();
    completer.complete(
      const Right(PaginatedResult(items: [guest2], pageIndex: 2, totalPages: 2, totalItems: 2)),
    );
    await first;
    await second;

    verify(() => eventGuestRepository.getEventGuests(1, groupId: null, status: null, pageIndex: 2, pageSize: 20))
        .called(1);
  });

  test('loadMore preserves existing items and resets isLoadingMore on failure', () async {
    when(() => eventGuestRepository.getEventGuests(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [guest1], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load(1);

    when(() => eventGuestRepository.getEventGuests(1, groupId: null, status: null, pageIndex: 2, pageSize: 20))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    await cubit.loadMore();

    final state = cubit.state as EventGuestsListSuccess;
    expect(state.guests, [guest1]);
    expect(state.pageIndex, 1);
    expect(state.hasNextPage, isTrue);
    expect(state.isLoadingMore, isFalse);
  });
}

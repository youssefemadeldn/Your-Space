import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/events/domain/entities/event.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_progress_summary.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_details_cubit/event_details_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_details_cubit/event_details_state.dart';

class MockEventRepository extends Mock implements EventRepository {}

class MockEventGuestRepository extends Mock implements EventGuestRepository {}

void main() {
  late MockEventRepository eventRepository;
  late MockEventGuestRepository eventGuestRepository;
  late DataRefreshBus dataRefreshBus;
  late EventDetailsCubit cubit;

  setUp(() {
    eventRepository = MockEventRepository();
    eventGuestRepository = MockEventGuestRepository();
    dataRefreshBus = DataRefreshBus();
    cubit = EventDetailsCubit(eventRepository, eventGuestRepository, dataRefreshBus);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with the event and its guest progress', () async {
    when(() => eventRepository.getEventById(1))
        .thenAnswer((_) async => const Right(Event(id: 1, name: "Sara's Birthday")));
    when(() => eventGuestRepository.getProgress(1)).thenAnswer(
      (_) async => const Right(EventGuestProgressSummary(
        eventId: 1,
        totalGuestCount: 3,
        notInvitedCount: 1,
        invitedCount: 2,
        skippedCount: 0,
        groups: [],
      )),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const EventDetailsLoading(),
        isA<EventDetailsSuccess>()
            .having((s) => s.event.id, 'event.id', 1)
            .having((s) => s.progress.eventId, 'progress.eventId', 1),
      ]),
    );

    unawaited(cubit.loadDetails(1));
    await expectation;
  });

  test('emits an Error when the event id does not exist, without calling getProgress', () async {
    when(() => eventRepository.getEventById(999999)).thenAnswer(
      (_) async => const Left(ServerFailure(statusCode: 404, message: 'Not found', errorCode: 'Event.NotFound')),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const EventDetailsLoading(), isA<EventDetailsError>()]),
    );

    unawaited(cubit.loadDetails(999999));
    await expectation;
    verifyNever(() => eventGuestRepository.getProgress(any()));
  });

  group('DataRefreshBus', () {
    // Bonus fix: EventDetailsScreen stays alive underneath when the user
    // goes to Manage Guests / Add Guests and pops back — same root cause as
    // the tab-level bug, one level deeper in the navigation stack.
    Future<void> loadSuccessfully() async {
      when(() => eventRepository.getEventById(1))
          .thenAnswer((_) async => const Right(Event(id: 1, name: "Sara's Birthday")));
      when(() => eventGuestRepository.getProgress(1)).thenAnswer(
        (_) async => const Right(
          EventGuestProgressSummary(
              eventId: 1, totalGuestCount: 3, notInvitedCount: 1, invitedCount: 2, skippedCount: 0, groups: []),
        ),
      );
      await cubit.loadDetails(1);
    }

    test('an `eventGuests` notification re-fetches event + progress, no Loading flash', () async {
      await loadSuccessfully();

      when(() => eventGuestRepository.getProgress(1)).thenAnswer(
        (_) async => const Right(
          EventGuestProgressSummary(
              eventId: 1, totalGuestCount: 3, notInvitedCount: 0, invitedCount: 3, skippedCount: 0, groups: []),
        ),
      );

      final states = <dynamic>[];
      final sub = cubit.stream.listen(states.add);

      dataRefreshBus.notify(DataScope.eventGuests);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(states, isNot(contains(isA<EventDetailsLoading>())));
      expect(
        cubit.state,
        isA<EventDetailsSuccess>().having((s) => s.progress.invitedCount, 'progress.invitedCount', 3),
      );
    });

    test('an `events` notification also triggers a re-fetch (event fields may have changed)', () async {
      await loadSuccessfully();

      when(() => eventRepository.getEventById(1))
          .thenAnswer((_) async => const Right(Event(id: 1, name: 'Renamed Birthday')));

      dataRefreshBus.notify(DataScope.events);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<EventDetailsSuccess>().having((s) => s.event.name, 'event.name', 'Renamed Birthday'));
    });

    test('a failed background refresh keeps the last-good details on screen', () async {
      await loadSuccessfully();
      final beforeRefresh = cubit.state;

      when(() => eventRepository.getEventById(1)).thenAnswer((_) async => const Left(NetworkFailure()));

      dataRefreshBus.notify(DataScope.events);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, beforeRefresh);
    });
  });
}

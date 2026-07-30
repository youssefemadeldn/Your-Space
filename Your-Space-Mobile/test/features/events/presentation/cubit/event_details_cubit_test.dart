import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
  late EventDetailsCubit cubit;

  setUp(() {
    eventRepository = MockEventRepository();
    eventGuestRepository = MockEventGuestRepository();
    cubit = EventDetailsCubit(eventRepository, eventGuestRepository);
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
}

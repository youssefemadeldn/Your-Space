import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/features/events/domain/entities/event.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_form_cubit/event_form_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_form_cubit/event_form_state.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository repository;
  late EventFormCubit cubit;

  setUp(() {
    repository = MockEventRepository();
    cubit = EventFormCubit(repository);
  });

  tearDown(() => cubit.close());

  test('initialize(null) emits Ready with event null (create mode), no network call', () async {
    await cubit.initialize(null);
    expect((cubit.state as EventFormReady).event, isNull);
    verifyNever(() => repository.getEventById(any()));
  });

  test('initialize(id) emits [Loading, Ready] pre-filled with that event (edit mode)', () async {
    when(() => repository.getEventById(1))
        .thenAnswer((_) async => const Right(Event(id: 1, name: "Sara's Birthday")));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const EventFormLoading(),
        isA<EventFormReady>().having((s) => s.event?.id, 'event.id', 1),
      ]),
    );

    unawaited(cubit.initialize(1));
    await expectation;
  });

  test('submit with no eventId creates a new event', () async {
    when(() => repository.createEvent(
          name: any(named: 'name'),
          nameAr: any(named: 'nameAr'),
          eventDate: any(named: 'eventDate'),
          notes: any(named: 'notes'),
        )).thenAnswer((_) async => const Right(Event(id: 3, name: 'New Event')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const EventFormSubmitting(),
        isA<EventFormSuccess>().having((s) => s.event.name, 'event.name', 'New Event'),
      ]),
    );

    unawaited(cubit.submit(name: 'New Event'));
    await expectation;
  });

  test('submit with an eventId updates the existing event', () async {
    when(() => repository.updateEvent(
          id: any(named: 'id'),
          name: any(named: 'name'),
          nameAr: any(named: 'nameAr'),
          eventDate: any(named: 'eventDate'),
          notes: any(named: 'notes'),
        )).thenAnswer((_) async => const Right(Event(id: 1, name: 'Renamed Event')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const EventFormSubmitting(),
        isA<EventFormSuccess>().having((s) => s.event.name, 'event.name', 'Renamed Event'),
      ]),
    );

    unawaited(cubit.submit(eventId: 1, name: 'Renamed Event'));
    await expectation;
  });
}

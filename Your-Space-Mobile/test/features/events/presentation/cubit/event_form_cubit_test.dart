import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_form_cubit/event_form_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_form_cubit/event_form_state.dart';

void main() {
  late MockDataStore store;
  late EventFormCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = EventFormCubit(store);
  });

  tearDown(() => cubit.close());

  test('initialize(null) emits Ready with event null (create mode)', () {
    cubit.initialize(null);
    expect((cubit.state as EventFormReady).event, isNull);
  });

  test('initialize(id) emits Ready pre-filled with that event (edit mode)', () {
    final event = store.events().first;
    cubit.initialize(event.id);
    expect((cubit.state as EventFormReady).event?.id, event.id);
  });

  test('submit with no eventId creates a new event', () async {
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const EventFormSubmitting(),
        isA<EventFormSuccess>().having((s) => s.event.name, 'event.name', 'New Event'),
      ]),
    );

    unawaited(cubit.submit(name: 'New Event'));
    await expectation;

    expect(store.events().map((e) => e.name), contains('New Event'));
  });

  test('submit with an eventId updates the existing event', () async {
    final event = store.events().first;

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const EventFormSubmitting(),
        isA<EventFormSuccess>().having((s) => s.event.name, 'event.name', 'Renamed Event'),
      ]),
    );

    unawaited(cubit.submit(eventId: event.id, name: 'Renamed Event'));
    await expectation;
  });
}

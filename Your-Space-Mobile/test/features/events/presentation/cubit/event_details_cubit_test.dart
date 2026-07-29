import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_details_cubit/event_details_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_details_cubit/event_details_state.dart';

void main() {
  late MockDataStore store;
  late EventDetailsCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = EventDetailsCubit(store);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with the event and its guest progress', () async {
    final event = store.events().first;

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const EventDetailsLoading(),
        isA<EventDetailsSuccess>()
            .having((s) => s.event.id, 'event.id', event.id)
            .having((s) => s.progress.eventId, 'progress.eventId', event.id),
      ]),
    );

    unawaited(cubit.loadDetails(event.id));
    await expectation;
  });

  test('emits an Error when the event id does not exist', () async {
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const EventDetailsLoading(), isA<EventDetailsError>()]),
    );

    unawaited(cubit.loadDetails(999999));
    await expectation;
  });
}

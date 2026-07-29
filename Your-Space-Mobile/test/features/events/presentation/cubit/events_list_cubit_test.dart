import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/events_list_cubit/events_list_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/events_list_cubit/events_list_state.dart';

void main() {
  late MockDataStore store;
  late EventsListCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = EventsListCubit(store);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with all events on load', () async {
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const EventsListLoading(),
        isA<EventsListSuccess>().having((s) => s.events.length, 'events.length', store.events().length),
      ]),
    );

    unawaited(cubit.load());
    await expectation;
  });

  test('search narrows the list without a Loading flash', () async {
    await cubit.load();

    final expectation = expectLater(
      cubit.stream,
      emits(isA<EventsListSuccess>().having((s) => s.events.length, 'events.length', 1)),
    );

    cubit.search("Sara's Birthday");
    await expectation;
  });
}

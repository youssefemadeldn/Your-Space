import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/features/events/domain/entities/event.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/events_list_cubit/events_list_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/events_list_cubit/events_list_state.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository repository;
  late DataRefreshBus dataRefreshBus;
  late EventsListCubit cubit;

  const event1 = Event(id: 1, name: "Sara's Birthday", totalGuestCount: 5);
  const event2 = Event(id: 2, name: 'New Year Gathering');

  void stubEvents({String? search, required int limit, required List<Event> events, required int total}) {
    when(() => repository.watchEvents(search: search, limit: limit)).thenAnswer((_) => Stream.value(events));
    when(() => repository.countEvents(search: search)).thenAnswer((_) async => total);
  }

  setUp(() {
    repository = MockEventRepository();
    dataRefreshBus = DataRefreshBus();
    cubit = EventsListCubit(repository, dataRefreshBus);
    when(() => repository.refreshEvents()).thenAnswer((_) async => const Right(unit));
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with the first window on load', () async {
    stubEvents(limit: 20, events: const [event1, event2], total: 2);

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const EventsListLoading(),
        isA<EventsListSuccess>()
            .having((s) => s.events.length, 'events.length', 2)
            .having((s) => s.hasNextPage, 'hasNextPage', false),
      ]),
    );

    await cubit.load();
    await expectation;
  });

  test('emits [Loading, Error] when the local read throws', () async {
    when(() => repository.watchEvents(search: null, limit: 20)).thenAnswer((_) => Stream.error(Exception('boom')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const EventsListLoading(), isA<EventsListError>()]),
    );

    await cubit.load();
    await expectation;
  });

  test('search debounces then resubscribes with the new filter', () async {
    stubEvents(limit: 20, events: const [event1, event2], total: 2);
    await cubit.load();

    stubEvents(search: "Sara's Birthday", limit: 20, events: const [event1], total: 1);

    cubit.search("Sara's Birthday");
    await Future.delayed(const Duration(milliseconds: 500));

    expect(cubit.state, isA<EventsListSuccess>().having((s) => s.events, 'events', [event1]));
  });

  test('search on an un-loaded cubit is a no-op', () async {
    cubit.search("Sara's Birthday");
    await Future.delayed(const Duration(milliseconds: 500));
    expect(cubit.state, isA<EventsListInitial>());
    verifyNever(() => repository.watchEvents(search: any(named: 'search'), limit: any(named: 'limit')));
  });

  test('loadMore grows the limit and hasNextPage reflects the exact count', () async {
    stubEvents(limit: 20, events: const [event1], total: 2);
    await cubit.load();
    expect((cubit.state as EventsListSuccess).hasNextPage, isTrue);

    stubEvents(limit: 40, events: const [event1, event2], total: 2);

    await cubit.loadMore();

    final state = cubit.state as EventsListSuccess;
    expect(state.events, [event1, event2]);
    expect(state.limit, 40);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    stubEvents(limit: 20, events: const [event1], total: 1);
    await cubit.load();

    await cubit.loadMore();

    verifyNever(() => repository.watchEvents(search: any(named: 'search'), limit: 40));
  });

  test('refresh re-subscribes and kicks a background refreshEvents pull, no Loading flash', () async {
    stubEvents(limit: 20, events: const [event1], total: 1);
    await cubit.load();

    stubEvents(limit: 20, events: const [event1, event2], total: 2);

    final states = <dynamic>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.refresh();
    await sub.cancel();

    expect(states, isNot(contains(isA<EventsListLoading>())));
    expect(cubit.state, isA<EventsListSuccess>().having((s) => s.events, 'events', [event1, event2]));
    verify(() => repository.refreshEvents()).called(1);
  });

  group('DataRefreshBus', () {
    // Event/EventGuest mutations aren't outbox-driven yet (rows 9.3/9.9), so
    // `totalGuestCount` only updates once a background `refreshEvents()`
    // pull lands — this listener bridges that gap until row 9.10 retires it.
    test('an `events` notification triggers a background refreshEvents() pull', () async {
      stubEvents(limit: 20, events: const [event1, event2], total: 2);
      await cubit.load();

      dataRefreshBus.notify(DataScope.events);
      await Future<void>.delayed(Duration.zero);

      verify(() => repository.refreshEvents()).called(1);
    });

    test('an `eventGuests` notification also triggers a background refreshEvents() pull', () async {
      stubEvents(limit: 20, events: const [event1, event2], total: 2);
      await cubit.load();

      dataRefreshBus.notify(DataScope.eventGuests);
      await Future<void>.delayed(Duration.zero);

      verify(() => repository.refreshEvents()).called(1);
    });
  });
}

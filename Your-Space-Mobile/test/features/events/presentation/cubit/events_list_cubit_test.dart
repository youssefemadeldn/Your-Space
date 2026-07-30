import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/features/events/domain/entities/event.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/events_list_cubit/events_list_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/events_list_cubit/events_list_state.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository repository;
  late EventsListCubit cubit;

  const event1 = Event(id: 1, name: "Sara's Birthday", totalGuestCount: 5);
  const event2 = Event(id: 2, name: 'New Year Gathering');

  setUp(() {
    repository = MockEventRepository();
    cubit = EventsListCubit(repository);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with the first page on load', () async {
    when(() => repository.getEvents(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async =>
          const Right(PaginatedResult(items: [event1, event2], pageIndex: 1, totalPages: 1, totalItems: 2)),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const EventsListLoading(),
        isA<EventsListSuccess>().having((s) => s.events.length, 'events.length', 2),
      ]),
    );

    unawaited(cubit.load());
    await expectation;
  });

  test('search debounces then narrows the list without a Loading flash', () async {
    when(() => repository.getEvents(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async =>
          const Right(PaginatedResult(items: [event1, event2], pageIndex: 1, totalPages: 1, totalItems: 2)),
    );
    await cubit.load();

    when(() => repository.getEvents(search: "Sara's Birthday", pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [event1], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );

    cubit.search("Sara's Birthday");
    await Future.delayed(const Duration(milliseconds: 500));

    expect(cubit.state, isA<EventsListSuccess>().having((s) => s.events, 'events', [event1]));
  });
}

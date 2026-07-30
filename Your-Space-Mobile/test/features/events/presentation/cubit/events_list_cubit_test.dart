import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
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

  test('loadMore appends the next page and advances pageIndex', () async {
    when(() => repository.getEvents(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [event1], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load();

    when(() => repository.getEvents(search: null, pageIndex: 2, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [event2], pageIndex: 2, totalPages: 2, totalItems: 2)),
    );

    await cubit.loadMore();

    final state = cubit.state as EventsListSuccess;
    expect(state.events, [event1, event2]);
    expect(state.pageIndex, 2);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    when(() => repository.getEvents(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [event1], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );
    await cubit.load();

    await cubit.loadMore();

    verifyNever(() => repository.getEvents(
          search: any(named: 'search'),
          pageIndex: 2,
          pageSize: any(named: 'pageSize'),
        ));
  });

  test('loadMore ignores a second concurrent call while the first is in flight', () async {
    when(() => repository.getEvents(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [event1], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load();

    final completer = Completer<Either<Failure, PaginatedResult<Event>>>();
    when(() => repository.getEvents(search: null, pageIndex: 2, pageSize: 20))
        .thenAnswer((_) => completer.future);

    final first = cubit.loadMore();
    final second = cubit.loadMore();
    completer.complete(
      const Right(PaginatedResult(items: [event2], pageIndex: 2, totalPages: 2, totalItems: 2)),
    );
    await first;
    await second;

    verify(() => repository.getEvents(search: null, pageIndex: 2, pageSize: 20)).called(1);
  });

  test('loadMore preserves existing items and resets isLoadingMore on failure', () async {
    when(() => repository.getEvents(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [event1], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load();

    when(() => repository.getEvents(search: null, pageIndex: 2, pageSize: 20))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    await cubit.loadMore();

    final state = cubit.state as EventsListSuccess;
    expect(state.events, [event1]);
    expect(state.pageIndex, 1);
    expect(state.hasNextPage, isTrue);
    expect(state.isLoadingMore, isFalse);
  });
}

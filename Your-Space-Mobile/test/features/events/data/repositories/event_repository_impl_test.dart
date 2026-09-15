import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/events/data/datasources/base_event_data_source.dart';
import 'package:your_space_mobile/features/events/data/datasources/event_local_data_source_impl.dart';
import 'package:your_space_mobile/features/events/data/models/create_event_request.dart';
import 'package:your_space_mobile/features/events/data/models/event_changes_response.dart';
import 'package:your_space_mobile/features/events/data/models/event_response.dart';
import 'package:your_space_mobile/features/events/data/models/update_event_request.dart';
import 'package:your_space_mobile/features/events/data/repositories/event_repository_impl.dart';
import 'package:your_space_mobile/features/events/domain/entities/event.dart';

class MockBaseEventDataSource extends Mock implements BaseEventDataSource {}

class MockEventLocalDataSourceImpl extends Mock implements EventLocalDataSourceImpl {}

void main() {
  late MockBaseEventDataSource remote;
  late MockEventLocalDataSourceImpl local;
  late EventRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const Event(id: 0, name: ''));
    registerFallbackValue(const CreateEventRequest(name: ''));
    registerFallbackValue(const UpdateEventRequest(id: 0, name: ''));
    registerFallbackValue(const <Event>[]);
  });

  setUp(() {
    remote = MockBaseEventDataSource();
    local = MockEventLocalDataSourceImpl();
    repository = EventRepositoryImpl(remote, local);
    when(
      () => local.queueEventMutation(
        event: any(named: 'event'),
        operation: any(named: 'operation'),
        payloadJson: any(named: 'payloadJson'),
      ),
    ).thenAnswer((_) async => 99);
    when(() => local.applyEventsSnapshot(any())).thenAnswer((_) async {});
    when(() => local.applyEventChanges(upserts: any(named: 'upserts'), tombstoneIds: any(named: 'tombstoneIds')))
        .thenAnswer((_) async {});
    when(() => local.saveEventsSyncCursor(any())).thenAnswer((_) async {});
  });

  test('getEventById maps the response to an entity', () async {
    when(() => remote.getEventById(1)).thenAnswer(
      (_) async => const Right(EventResponse(id: 1, name: "Sara's Birthday", totalGuestCount: 5)),
    );

    final result = await repository.getEventById(1);

    expect(result, const Right(Event(id: 1, name: "Sara's Birthday", totalGuestCount: 5)));
  });

  test('getEventById propagates a failure unchanged', () async {
    const failure = ServerFailure(statusCode: 404, message: 'Not found', errorCode: 'Event.NotFound');
    when(() => remote.getEventById(999)).thenAnswer((_) async => const Left(failure));

    final result = await repository.getEventById(999);

    expect(result, const Left(failure));
  });

  test('watchEvents delegates straight to the local data source', () {
    when(() => local.watchEvents(search: 'sara', limit: 20)).thenAnswer(
      (_) => Stream.value(const [Event(id: 1, name: "Sara's Birthday")]),
    );

    final stream = repository.watchEvents(search: 'sara', limit: 20);

    expect(stream, emits(const [Event(id: 1, name: "Sara's Birthday")]));
  });

  test('countEvents delegates straight to the local data source', () async {
    when(() => local.countEvents(search: null)).thenAnswer((_) async => 5);

    final count = await repository.countEvents();

    expect(count, 5);
  });

  group('createEvent (pure optimistic path)', () {
    test('queues a negative-id create via the outbox and returns immediately', () async {
      final result = await repository.createEvent(name: 'Book club');

      expect(result.isRight(), isTrue);
      final event = result.getOrElse(() => throw StateError('expected Right'));
      expect(event.id, lessThan(0));
      expect(event.name, 'Book club');

      final captured = verify(
        () => local.queueEventMutation(
          event: captureAny(named: 'event'),
          operation: captureAny(named: 'operation'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      expect((captured[0] as Event).id, lessThan(0));
      expect(captured[1], 'create');
      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['name'], 'Book club');

      verifyNever(() => remote.createEvent(any()));
    });
  });

  group('updateEvent (pure optimistic path)', () {
    test('queues an update against the given id via the outbox and returns immediately', () async {
      final result = await repository.updateEvent(id: 1, name: 'Book club (Updated)');

      expect(result, isA<Right<Failure, Event>>());
      final captured = verify(
        () => local.queueEventMutation(
          event: captureAny(named: 'event'),
          operation: captureAny(named: 'operation'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      expect((captured[0] as Event).id, 1);
      expect(captured[1], 'update');
      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['id'], 1);
      expect(payload['name'], 'Book club (Updated)');

      verifyNever(() => remote.updateEvent(any()));
    });
  });

  group('refreshEvents', () {
    test('single page, no more data: applies the page and persists its cursor', () async {
      when(() => local.getEventsSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getEventChanges(since: 0, pageSize: 200)).thenAnswer(
        (_) async => Right(
          EventChangesResponse(
            upserts: [_toResponse(1)],
            tombstoneIds: const [5],
            cursor: 137,
            hasMore: false,
          ),
        ),
      );

      final result = await repository.refreshEvents();

      expect(result, const Right(unit));
      final captured = verify(
        () => local.applyEventChanges(
          upserts: captureAny(named: 'upserts'),
          tombstoneIds: captureAny(named: 'tombstoneIds'),
        ),
      ).captured;
      expect((captured[0] as List<Event>).map((e) => e.id), [1]);
      expect(captured[1], [5]);
      verify(() => local.saveEventsSyncCursor(137)).called(1);
    });

    test('multi-page loop threads the returned cursor forward as the next since', () async {
      when(() => local.getEventsSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getEventChanges(since: 0, pageSize: 200)).thenAnswer(
        (_) async => Right(
          EventChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [], cursor: 50, hasMore: true),
        ),
      );
      when(() => remote.getEventChanges(since: 50, pageSize: 200)).thenAnswer(
        (_) async => Right(
          EventChangesResponse(upserts: [_toResponse(2)], tombstoneIds: const [], cursor: 90, hasMore: false),
        ),
      );

      final result = await repository.refreshEvents();

      expect(result, const Right(unit));
      verify(() => remote.getEventChanges(since: 0, pageSize: 200)).called(1);
      verify(() => remote.getEventChanges(since: 50, pageSize: 200)).called(1);
      verify(
        () => local.applyEventChanges(upserts: any(named: 'upserts'), tombstoneIds: any(named: 'tombstoneIds')),
      ).called(2);
      verify(() => local.saveEventsSyncCursor(50)).called(1);
      verify(() => local.saveEventsSyncCursor(90)).called(1);
    });

    test('resumes from a previously stored cursor', () async {
      when(() => local.getEventsSyncCursor()).thenAnswer((_) async => 300);
      when(() => remote.getEventChanges(since: 300, pageSize: 200)).thenAnswer(
        (_) async => const Right(EventChangesResponse(upserts: [], tombstoneIds: [], cursor: 300, hasMore: false)),
      );

      final result = await repository.refreshEvents();

      expect(result, const Right(unit));
      verify(() => remote.getEventChanges(since: 300, pageSize: 200)).called(1);
    });

    test(
      'stops and returns Left immediately on a failing page, preserving prior pages\' persisted cursor',
      () async {
        when(() => local.getEventsSyncCursor()).thenAnswer((_) async => 0);
        when(() => remote.getEventChanges(since: 0, pageSize: 200)).thenAnswer(
          (_) async => Right(
            EventChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [], cursor: 50, hasMore: true),
          ),
        );
        const failure = NetworkFailure();
        when(() => remote.getEventChanges(since: 50, pageSize: 200)).thenAnswer((_) async => const Left(failure));

        final result = await repository.refreshEvents();

        expect(result, const Left(failure));
        verify(() => local.saveEventsSyncCursor(50)).called(1);
        verify(
          () => local.applyEventChanges(upserts: any(named: 'upserts'), tombstoneIds: any(named: 'tombstoneIds')),
        ).called(1);
        verify(() => remote.getEventChanges(since: 0, pageSize: 200)).called(1);
        verify(() => remote.getEventChanges(since: 50, pageSize: 200)).called(1);
        verifyNever(() => remote.getEventChanges(since: 90, pageSize: 200));
      },
    );

    test('stops after the defensive page cap when the server always says hasMore', () async {
      when(() => local.getEventsSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getEventChanges(since: any(named: 'since'), pageSize: 200)).thenAnswer((invocation) async {
        final since = invocation.namedArguments[#since] as int;
        return Right(EventChangesResponse(upserts: const [], tombstoneIds: const [], cursor: since + 1, hasMore: true));
      });

      final result = await repository.refreshEvents();

      expect(result, const Right(unit));
      verify(() => local.saveEventsSyncCursor(any())).called(50);
    });
  });
}

EventResponse _toResponse(int id) => EventResponse(id: id, name: 'Event $id', totalGuestCount: 0);

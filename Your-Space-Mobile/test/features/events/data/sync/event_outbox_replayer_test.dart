import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/events/data/datasources/base_event_data_source.dart';
import 'package:your_space_mobile/features/events/data/datasources/event_local_data_source_impl.dart';
import 'package:your_space_mobile/features/events/data/models/create_event_request.dart';
import 'package:your_space_mobile/features/events/data/models/event_response.dart';
import 'package:your_space_mobile/features/events/data/models/update_event_request.dart';
import 'package:your_space_mobile/features/events/data/sync/event_outbox_replayer.dart';
import 'package:your_space_mobile/features/events/domain/entities/event.dart';

class MockBaseEventDataSource extends Mock implements BaseEventDataSource {}

class MockEventLocalDataSourceImpl extends Mock implements EventLocalDataSourceImpl {}

OutboxTableData _row({
  int id = 1,
  int entityId = -1,
  required String operation,
  required String payloadJson,
}) =>
    OutboxTableData(
      id: id,
      entityType: 'event',
      entityId: entityId,
      operation: operation,
      payloadJson: payloadJson,
      createdAt: DateTime(2026),
      retryCount: 0,
    );

const _eventResponse = EventResponse(id: 999, name: 'Book club', totalGuestCount: 0);

void main() {
  late MockBaseEventDataSource remote;
  late MockEventLocalDataSourceImpl local;
  late EventOutboxReplayer replayer;

  setUpAll(() {
    registerFallbackValue(const CreateEventRequest(name: ''));
    registerFallbackValue(const UpdateEventRequest(id: 0, name: ''));
    registerFallbackValue(const Event(id: 0, name: ''));
  });

  setUp(() {
    remote = MockBaseEventDataSource();
    local = MockEventLocalDataSourceImpl();
    replayer = EventOutboxReplayer(remote, local);
    when(() => local.reconcileCreatedEvent(
          tempId: any(named: 'tempId'),
          realEvent: any(named: 'realEvent'),
          replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
        )).thenAnswer((_) async {});
    when(() => local.confirmSyncedEvent(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
  });

  test('entityType is event', () {
    expect(replayer.entityType, 'event');
  });

  group('create', () {
    test('success decodes the payload, calls remote.createEvent, and reconciles the temp id', () async {
      when(() => remote.createEvent(any())).thenAnswer((_) async => const Right(_eventResponse));
      final row = _row(id: 5, entityId: -42, operation: 'create', payloadJson: '{"name":"Book club"}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      final captured = verify(() => remote.createEvent(captureAny())).captured.single as CreateEventRequest;
      expect(captured.name, 'Book club');
      verify(
        () => local.reconcileCreatedEvent(tempId: -42, realEvent: _eventResponse.toEntity(), replayedOutboxRowId: 5),
      ).called(1);
    });

    test('failure returns Left and never reconciles', () async {
      const failure = NetworkFailure();
      when(() => remote.createEvent(any())).thenAnswer((_) async => const Left(failure));
      final row = _row(operation: 'create', payloadJson: '{"name":"Book club"}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.reconcileCreatedEvent(
            tempId: any(named: 'tempId'),
            realEvent: any(named: 'realEvent'),
            replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
          ));
    });
  });

  group('update', () {
    test('success decodes the payload, calls remote.updateEvent, and confirms the sync', () async {
      when(() => remote.updateEvent(any())).thenAnswer((_) async => const Right(_eventResponse));
      final row = _row(id: 7, entityId: 999, operation: 'update', payloadJson: '{"id":999,"name":"Book club"}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      final captured = verify(() => remote.updateEvent(captureAny())).captured.single as UpdateEventRequest;
      expect(captured.id, 999);
      verify(() => local.confirmSyncedEvent(_eventResponse.toEntity(), replayedOutboxRowId: 7)).called(1);
    });

    test('failure returns Left and never confirms', () async {
      const failure = ServerFailure(statusCode: 500, message: 'boom');
      when(() => remote.updateEvent(any())).thenAnswer((_) async => const Left(failure));
      final row = _row(operation: 'update', payloadJson: '{"id":999,"name":"Book club"}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.confirmSyncedEvent(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')));
    });
  });

  test('an unrecognized operation returns Left without throwing', () async {
    final row = _row(operation: 'delete', payloadJson: '{}');

    final result = await replayer.replay(row);

    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(remote);
  });
}

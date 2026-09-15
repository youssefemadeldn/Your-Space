import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/features/events/data/datasources/base_event_guest_data_source.dart';
import 'package:your_space_mobile/features/events/data/datasources/event_guest_local_data_source_impl.dart';
import 'package:your_space_mobile/features/events/data/models/add_persons_to_event_request.dart';
import 'package:your_space_mobile/features/events/data/models/bulk_add_guests_result_response.dart';
import 'package:your_space_mobile/features/events/data/models/event_guest_response.dart';
import 'package:your_space_mobile/features/events/data/models/mark_guest_invited_request.dart';
import 'package:your_space_mobile/features/events/data/sync/event_guest_outbox_replayer.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';

class MockBaseEventGuestDataSource extends Mock implements BaseEventGuestDataSource {}

class MockEventGuestLocalDataSourceImpl extends Mock implements EventGuestLocalDataSourceImpl {}

OutboxTableData _row({
  int id = 1,
  int entityId = -1,
  required String operation,
  required String payloadJson,
}) =>
    OutboxTableData(
      id: id,
      entityType: 'eventGuest',
      entityId: entityId,
      operation: operation,
      payloadJson: payloadJson,
      createdAt: DateTime(2026),
      retryCount: 0,
    );

const _guestResponse = EventGuestResponse(
  id: 999,
  personId: 10,
  personName: 'Sara Adel',
  groupId: 1,
  groupName: 'Family',
  status: EventGuestStatus.notInvited,
);

void main() {
  late MockBaseEventGuestDataSource remote;
  late MockEventGuestLocalDataSourceImpl local;
  late EventGuestOutboxReplayer replayer;

  setUpAll(() {
    registerFallbackValue(const AddPersonsToEventRequest(personIds: []));
    registerFallbackValue(const MarkGuestInvitedRequest(inviteMethod: InviteMethod.whatsApp));
    registerFallbackValue(const EventGuest(id: 0, eventId: 0, personId: 0, personName: '', groupId: 0, groupName: ''));
  });

  setUp(() {
    remote = MockBaseEventGuestDataSource();
    local = MockEventGuestLocalDataSourceImpl();
    replayer = EventGuestOutboxReplayer(remote, local);
    when(() => local.reconcileCreatedEventGuest(
          tempId: any(named: 'tempId'),
          realGuest: any(named: 'realGuest'),
          replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
        )).thenAnswer((_) async {});
    when(() => local.confirmSyncedEventGuest(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
    when(() => local.confirmDeletedEventGuest(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
  });

  test('entityType is eventGuest', () {
    expect(replayer.entityType, 'eventGuest');
  });

  group('create', () {
    test(
      'success calls addPersonsToEvent with a one-element list, re-resolves the real row, and reconciles',
      () async {
        when(() => remote.addPersonsToEvent(7, any())).thenAnswer(
          (_) async => const Right(BulkAddGuestsResultResponse(requestedCount: 1, addedCount: 1, alreadyPresentCount: 0)),
        );
        when(() => remote.getEventGuests(7, pageIndex: 1, pageSize: 200)).thenAnswer(
          (_) async => const Right(PaginatedResponse(items: [_guestResponse], pageIndex: 1, totalPages: 1, totalItems: 1)),
        );
        final row = _row(id: 5, entityId: -42, operation: 'create', payloadJson: '{"eventId":7,"personId":10}');

        final result = await replayer.replay(row);

        expect(result.isRight(), isTrue);
        final captured = verify(() => remote.addPersonsToEvent(7, captureAny())).captured.single as AddPersonsToEventRequest;
        expect(captured.personIds, [10]);
        verify(() => local.reconcileCreatedEventGuest(
              tempId: -42,
              realGuest: _guestResponse.toEntity(7),
              replayedOutboxRowId: 5,
            )).called(1);
      },
    );

    test('failure returns Left and never reconciles', () async {
      const failure = NetworkFailure();
      when(() => remote.addPersonsToEvent(7, any())).thenAnswer((_) async => const Left(failure));
      final row = _row(operation: 'create', payloadJson: '{"eventId":7,"personId":10}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.reconcileCreatedEventGuest(
            tempId: any(named: 'tempId'),
            realGuest: any(named: 'realGuest'),
            replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
          ));
    });
  });

  group('update', () {
    test('an Invited status calls markInvited and confirms the sync', () async {
      when(() => remote.markInvited(7, 999, any())).thenAnswer(
        (_) async => const Right(EventGuestResponse(
          id: 999,
          personId: 10,
          personName: 'Sara Adel',
          groupId: 1,
          groupName: 'Family',
          status: EventGuestStatus.invited,
          inviteMethod: InviteMethod.whatsApp,
        )),
      );
      final row = _row(
        id: 6,
        entityId: 999,
        operation: 'update',
        payloadJson: '{"eventId":7,"guestId":999,"status":"Invited","inviteMethod":"WhatsApp"}',
      );

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      verify(() => local.confirmSyncedEventGuest(any(), replayedOutboxRowId: 6)).called(1);
    });

    test('a Skipped status calls markSkipped', () async {
      when(() => remote.markSkipped(7, 999)).thenAnswer(
        (_) async => const Right(EventGuestResponse(
          id: 999,
          personId: 10,
          personName: 'Sara Adel',
          groupId: 1,
          groupName: 'Family',
          status: EventGuestStatus.skipped,
        )),
      );
      final row = _row(entityId: 999, operation: 'update', payloadJson: '{"eventId":7,"guestId":999,"status":"Skipped"}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      verify(() => remote.markSkipped(7, 999)).called(1);
    });

    test('a NotInvited status calls revertGuest', () async {
      when(() => remote.revertGuest(7, 999)).thenAnswer((_) async => const Right(_guestResponse));
      final row = _row(entityId: 999, operation: 'update', payloadJson: '{"eventId":7,"guestId":999,"status":"NotInvited"}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      verify(() => remote.revertGuest(7, 999)).called(1);
    });
  });

  group('delete', () {
    test('success calls removeGuest and confirms the delete', () async {
      when(() => remote.removeGuest(7, 999)).thenAnswer((_) async => const Right(unit));
      final row = _row(id: 8, entityId: 999, operation: 'delete', payloadJson: '{"eventId":7}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      verify(() => local.confirmDeletedEventGuest(999, replayedOutboxRowId: 8)).called(1);
    });
  });

  test('an unrecognized operation returns Left without throwing', () async {
    final row = _row(operation: 'bogus', payloadJson: '{"eventId":7}');

    final result = await replayer.replay(row);

    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(remote);
  });
}


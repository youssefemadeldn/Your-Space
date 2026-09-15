import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/outbox_replayer.dart';
import '../../domain/entities/event_guest_status.dart';
import '../datasources/base_event_guest_data_source.dart';
import '../datasources/event_guest_local_data_source_impl.dart';
import '../models/add_persons_to_event_request.dart';
import '../models/mark_guest_invited_request.dart';

/// `SyncService`'s entityType: 'eventGuest' strategy — mirrors
/// `CityOutboxReplayer`, but every mutation the mobile UI ever queues for
/// EventGuest resolves to one of two shapes:
///  - `'create'`: a single-person add, resolved client-side from a bulk-add
///    action before queuing (row 9 cross-cutting decision) — always replays
///    as `addPersonsToEvent` with a one-element list.
///  - `'update'`: a status transition (invite/skip/revert), replayed as the
///    matching `markInvited`/`markSkipped`/`revertGuest` call based on the
///    payload's `status` field.
///  - `'delete'`: `removeGuest`.
/// See `PersonOutboxReplayer`'s doc comment for why this class-level
/// `@Named` tag exists.
@Named('eventGuest')
@LazySingleton(as: OutboxReplayer)
class EventGuestOutboxReplayer implements OutboxReplayer {
  final BaseEventGuestDataSource _remote;
  final EventGuestLocalDataSourceImpl _local;

  EventGuestOutboxReplayer(@Named('remote') this._remote, @Named('local') this._local);

  @override
  String get entityType => 'eventGuest';

  @override
  Future<Either<Failure, Object?>> replay(OutboxTableData row) async {
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    final eventId = payload['eventId'] as int;
    switch (row.operation) {
      case 'create':
        final personId = payload['personId'] as int;
        final result =
            await _remote.addPersonsToEvent(eventId, AddPersonsToEventRequest(personIds: [personId]));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (_) async {
            // The bulk-add endpoint returns a count summary, not the created
            // guest row itself — re-fetch the just-created row's real id via
            // a fresh page-1 list read scoped to this person, mirroring how
            // the flat "all mine" pull will pick it up on the next Tier 3
            // cycle regardless. A synchronous re-read here keeps the temp-id
            // reconciliation (dependents, if any are ever added) working the
            // same transaction-shape as every other entity's 'create' case.
            final listResult = await _remote.getEventGuests(eventId, pageIndex: 1, pageSize: 200);
            final realGuest = listResult.fold(
              (_) => null,
              (page) => page.items.where((g) => g.personId == personId).map((g) => g.toEntity(eventId)).firstOrNull,
            );
            if (realGuest == null) {
              // Extremely unlikely (the add just succeeded) — treat as a
              // soft failure so the outbox row is retried rather than
              // silently dropping the reconciliation step.
              return const Left(UnexpectedFailure(message: 'Could not resolve the newly-added guest row'));
            }
            await _local.reconcileCreatedEventGuest(
              tempId: row.entityId,
              realGuest: realGuest,
              replayedOutboxRowId: row.id,
            );
            return Right(realGuest);
          },
        );
      case 'update':
        final guestId = payload['guestId'] as int;
        final status = EventGuestStatus.fromWire(payload['status'] as String);
        final result = switch (status) {
          EventGuestStatus.invited => await _remote.markInvited(
              eventId,
              guestId,
              MarkGuestInvitedRequest(inviteMethod: InviteMethod.fromWire(payload['inviteMethod'] as String)),
            ),
          EventGuestStatus.skipped => await _remote.markSkipped(eventId, guestId),
          EventGuestStatus.notInvited => await _remote.revertGuest(eventId, guestId),
        };
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final guest = response.toEntity(eventId);
            await _local.confirmSyncedEventGuest(guest, replayedOutboxRowId: row.id);
            return Right(guest);
          },
        );
      case 'delete':
        final guestId = row.entityId;
        final result = await _remote.removeGuest(eventId, guestId);
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (_) async {
            await _local.confirmDeletedEventGuest(guestId, replayedOutboxRowId: row.id);
            return const Right(null);
          },
        );
      default:
        return Left(UnexpectedFailure(message: 'Unsupported eventGuest outbox operation: ${row.operation}'));
    }
  }
}

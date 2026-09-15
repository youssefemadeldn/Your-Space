import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/outbox_replayer.dart';
import '../datasources/base_event_data_source.dart';
import '../datasources/event_local_data_source_impl.dart';
import '../models/create_event_request.dart';
import '../models/update_event_request.dart';

/// `SyncService`'s entityType: 'event' strategy — mirrors
/// `GroupOutboxReplayer` (create/update only; Event has no delete flow in
/// the mobile UI yet, matching Group's own shape). See
/// `PersonOutboxReplayer`'s doc comment for why this class-level `@Named`
/// tag exists.
@Named('event')
@LazySingleton(as: OutboxReplayer)
class EventOutboxReplayer implements OutboxReplayer {
  final BaseEventDataSource _remote;
  final EventLocalDataSourceImpl _local;

  EventOutboxReplayer(@Named('remote') this._remote, @Named('local') this._local);

  @override
  String get entityType => 'event';

  @override
  Future<Either<Failure, Object?>> replay(OutboxTableData row) async {
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    switch (row.operation) {
      case 'create':
        final result = await _remote.createEvent(_createRequestFrom(payload));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final realEvent = response.toEntity();
            await _local.reconcileCreatedEvent(
              tempId: row.entityId,
              realEvent: realEvent,
              replayedOutboxRowId: row.id,
            );
            return Right(realEvent);
          },
        );
      case 'update':
        final result = await _remote.updateEvent(_updateRequestFrom(payload));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final event = response.toEntity();
            await _local.confirmSyncedEvent(event, replayedOutboxRowId: row.id);
            return Right(event);
          },
        );
      default:
        return Left(UnexpectedFailure(message: 'Unsupported event outbox operation: ${row.operation}'));
    }
  }

  CreateEventRequest _createRequestFrom(Map<String, dynamic> json) => CreateEventRequest(
        name: json['name'] as String,
        nameAr: json['nameAr'] as String?,
        eventDate: json['eventDate'] == null ? null : DateTime.parse(json['eventDate'] as String),
        notes: json['notes'] as String?,
      );

  UpdateEventRequest _updateRequestFrom(Map<String, dynamic> json) => UpdateEventRequest(
        id: json['id'] as int,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String?,
        eventDate: json['eventDate'] == null ? null : DateTime.parse(json['eventDate'] as String),
        notes: json['notes'] as String?,
      );
}

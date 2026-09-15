import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/person_relationship.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/outbox_replayer.dart';
import '../datasources/base_person_relationship_data_source.dart';
import '../datasources/person_relationship_local_data_source_impl.dart';
import '../models/create_person_relationship_request.dart';

/// `SyncService`'s entityType: 'personRelationship' strategy — mirrors
/// `EventGuestOutboxReplayer`, but this is Row 9's other new mechanism:
/// every 'create' replays as one pair-reconciliation, never a single-row
/// one. See `PersonOutboxReplayer`'s doc comment for why this class-level
/// `@Named` tag exists.
@Named('personRelationship')
@LazySingleton(as: OutboxReplayer)
class PersonRelationshipOutboxReplayer implements OutboxReplayer {
  final BasePersonRelationshipDataSource _remote;
  final PersonRelationshipLocalDataSourceImpl _local;

  PersonRelationshipOutboxReplayer(@Named('remote') this._remote, @Named('local') this._local);

  @override
  String get entityType => 'personRelationship';

  @override
  Future<Either<Failure, Object?>> replay(OutboxTableData row) async {
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    switch (row.operation) {
      case 'create':
        final personId = payload['personId'] as int;
        final request = CreatePersonRelationshipRequest(
          relatedPersonId: payload['relatedPersonId'] as int,
          relationType: RelationType.fromWire(payload['relationType'] as String),
        );
        final result = await _remote.createRelationship(personId, request);
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            // The temp inverse id was linked onto the forward row at queue
            // time (`inverseId`) — read it back before it's overwritten, and
            // reuse its already-correct `relatedPersonName` (the subject
            // person's own name, resolved locally at queue time).
            final tempForward = await _local.getLocalRelationship(row.entityId);
            final tempInverseId = tempForward?.inverseId;
            if (tempInverseId == null) {
              return const Left(UnexpectedFailure(message: 'Missing temp inverse id for queued relationship pair'));
            }
            final tempInverse = await _local.getLocalRelationship(tempInverseId);

            final realForward = PersonRelationship(
              id: response.id,
              personId: response.personId,
              relatedPersonId: response.relatedPersonId,
              relatedPersonName: response.relatedPersonName,
              relationType: response.relationType,
              inverseId: response.inverseId,
            );
            final realInverse = PersonRelationship(
              id: response.inverseId,
              personId: response.relatedPersonId,
              relatedPersonId: response.personId,
              relatedPersonName: tempInverse?.relatedPersonName ?? '',
              relationType: response.inverseRelationType,
              inverseId: response.id,
            );

            await _local.confirmSyncedPersonRelationshipPair(
              tempForwardId: row.entityId,
              tempInverseId: tempInverseId,
              realForward: realForward,
              realInverse: realInverse,
              replayedOutboxRowId: row.id,
            );
            return Right(realForward);
          },
        );
      case 'delete':
        final personId = payload['personId'] as int;
        final result = await _remote.deleteRelationship(personId, row.entityId);
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (_) async {
            await _local.confirmDeletedPersonRelationship(row.entityId, replayedOutboxRowId: row.id);
            return const Right(null);
          },
        );
      default:
        return Left(UnexpectedFailure(message: 'Unsupported personRelationship outbox operation: ${row.operation}'));
    }
  }
}

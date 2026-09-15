import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/person_image_ref.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/outbox_replayer.dart';
import '../datasources/base_person_image_data_source.dart';
import '../datasources/person_image_local_data_source_impl.dart';

/// `SyncService`'s entityType: 'personImage' strategy — mirrors design doc
/// §9's own worked example exactly: reads the staged file off disk at
/// replay time and performs the existing multipart upload call unchanged.
/// A missing file at replay time (the user cleared app storage between
/// staging and sync) drops the row with a logged warning rather than
/// retrying forever, per §9's own stated policy. See
/// `PersonOutboxReplayer`'s doc comment for why this class-level `@Named`
/// tag exists.
@Named('personImage')
@LazySingleton(as: OutboxReplayer)
class PersonImageOutboxReplayer implements OutboxReplayer {
  final BasePersonImageDataSource _remote;
  final PersonImageLocalDataSourceImpl _local;

  PersonImageOutboxReplayer(@Named('remote') this._remote, @Named('local') this._local);

  @override
  String get entityType => 'personImage';

  @override
  Future<Either<Failure, Object?>> replay(OutboxTableData row) async {
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    final personId = payload['personId'] as int;
    switch (row.operation) {
      case 'create':
        final localFilePath = payload['localFilePath'] as String;
        final file = File(localFilePath);
        if (!await file.exists()) {
          // §9: drop, don't retry forever — the staged file is gone (app
          // storage was cleared between staging and sync). Resolve the
          // outbox row as done so it stops being re-attempted.
          await _local.discardOutboxRow(row.id);
          return const Right(null);
        }
        final result = await _remote.uploadImage(personId, file);
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final image = response.toEntity();
            await _local.confirmUploadedImage(
              PersonImageRef(
                id: image.id,
                personId: personId,
                objectKey: response.objectKey ?? '',
                isPrimary: image.isPrimary,
              ),
              replayedOutboxRowId: row.id,
            );
            return Right(image);
          },
        );
      case 'update':
        final result = await _remote.setPrimary(personId, row.entityId);
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            await _local.confirmSyncedPrimary(row.entityId, replayedOutboxRowId: row.id);
            return Right(response.toEntity());
          },
        );
      case 'delete':
        final result = await _remote.deleteImage(personId, row.entityId);
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (_) async {
            await _local.confirmDeletedImage(row.entityId, replayedOutboxRowId: row.id);
            return const Right(null);
          },
        );
      default:
        return Left(UnexpectedFailure(message: 'Unsupported personImage outbox operation: ${row.operation}'));
    }
  }
}

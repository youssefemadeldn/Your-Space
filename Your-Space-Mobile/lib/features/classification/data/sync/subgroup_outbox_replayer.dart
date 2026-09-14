import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/outbox_replayer.dart';
import '../datasources/base_subgroup_data_source.dart';
import '../datasources/subgroup_local_data_source_impl.dart';
import '../models/create_subgroup_request.dart';
import '../models/update_subgroup_request.dart';

/// `SyncService`'s entityType: 'subgroup' strategy — mirrors
/// `CityOutboxReplayer` exactly, including its real `'delete'` case. See
/// `PersonOutboxReplayer`'s doc comment for why this class-level `@Named`
/// tag exists.
@Named('subgroup')
@LazySingleton(as: OutboxReplayer)
class SubGroupOutboxReplayer implements OutboxReplayer {
  final BaseSubGroupDataSource _remote;
  final SubGroupLocalDataSourceImpl _local;

  SubGroupOutboxReplayer(@Named('remote') this._remote, @Named('local') this._local);

  @override
  String get entityType => 'subgroup';

  @override
  Future<Either<Failure, Object?>> replay(OutboxTableData row) async {
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    final groupId = payload['groupId'] as int;
    switch (row.operation) {
      case 'create':
        final result = await _remote.createSubGroup(groupId, _createRequestFrom(payload));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final realSubGroup = response.toEntity();
            await _local.reconcileCreatedSubGroup(
              tempId: row.entityId,
              realSubGroup: realSubGroup,
              replayedOutboxRowId: row.id,
            );
            return Right(realSubGroup);
          },
        );
      case 'update':
        final result = await _remote.updateSubGroup(groupId, row.entityId, _updateRequestFrom(payload));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final subGroup = response.toEntity();
            await _local.confirmSyncedSubGroup(subGroup, replayedOutboxRowId: row.id);
            return Right(subGroup);
          },
        );
      case 'delete':
        final result = await _remote.deleteSubGroup(groupId, row.entityId);
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (_) async {
            await _local.confirmDeletedSubGroup(row.entityId, replayedOutboxRowId: row.id);
            return const Right(null);
          },
        );
      default:
        return Left(UnexpectedFailure(message: 'Unsupported subgroup outbox operation: ${row.operation}'));
    }
  }

  CreateSubGroupRequest _createRequestFrom(Map<String, dynamic> json) =>
      CreateSubGroupRequest(name: json['name'] as String, nameAr: json['nameAr'] as String?);

  UpdateSubGroupRequest _updateRequestFrom(Map<String, dynamic> json) =>
      UpdateSubGroupRequest(name: json['name'] as String, nameAr: json['nameAr'] as String?);
}

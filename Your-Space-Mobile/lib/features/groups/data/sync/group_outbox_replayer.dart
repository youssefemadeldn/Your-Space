import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/outbox_replayer.dart';
import '../datasources/base_group_data_source.dart';
import '../datasources/group_local_data_source_impl.dart';
import '../models/create_group_request.dart';
import '../models/update_group_request.dart';

/// `SyncService`'s entityType: 'group' strategy — mirrors
/// `PersonOutboxReplayer`. The only place `BaseGroupDataSource`'s
/// create/update methods are called from now that Tier 2 has replaced
/// `GroupRepositoryImpl`'s direct remote calls with the outbox (row 7.3).
/// See `PersonOutboxReplayer`'s doc comment for why this class-level
/// `@Named` tag exists (distinct from the constructor's own `@Named`
/// params) — it avoids colliding with `PersonOutboxReplayer`'s registration
/// under injectable's duplicate-registration check.
@Named('group')
@LazySingleton(as: OutboxReplayer)
class GroupOutboxReplayer implements OutboxReplayer {
  final BaseGroupDataSource _remote;
  final GroupLocalDataSourceImpl _local;

  GroupOutboxReplayer(@Named('remote') this._remote, @Named('local') this._local);

  @override
  String get entityType => 'group';

  @override
  Future<Either<Failure, Object?>> replay(OutboxTableData row) async {
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    switch (row.operation) {
      case 'create':
        final result = await _remote.createGroup(_createRequestFrom(payload));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final realGroup = response.toEntity();
            await _local.reconcileCreatedGroup(
              tempId: row.entityId,
              realGroup: realGroup,
              replayedOutboxRowId: row.id,
            );
            return Right(realGroup);
          },
        );
      case 'update':
        final result = await _remote.updateGroup(_updateRequestFrom(payload));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final group = response.toEntity();
            await _local.confirmSyncedGroup(group, replayedOutboxRowId: row.id);
            return Right(group);
          },
        );
      default:
        // No 'delete' exists in Groups' mobile UI yet — fail loudly rather
        // than silently drop, so a future delete feature can't accidentally
        // queue an unhandled operation without noticing.
        return Left(UnexpectedFailure(message: 'Unsupported group outbox operation: ${row.operation}'));
    }
  }

  CreateGroupRequest _createRequestFrom(Map<String, dynamic> json) =>
      CreateGroupRequest(name: json['name'] as String, nameAr: json['nameAr'] as String?);

  UpdateGroupRequest _updateRequestFrom(Map<String, dynamic> json) => UpdateGroupRequest(
        id: json['id'] as int,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String?,
      );
}

import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import '../../domain/repositories/base_subgroup_repository.dart';
import '../datasources/base_subgroup_data_source.dart';
import '../datasources/subgroup_local_data_source_impl.dart';
import '../models/create_subgroup_request.dart';
import '../models/update_subgroup_request.dart';

@LazySingleton(as: SubGroupRepository)
class SubGroupRepositoryImpl implements SubGroupRepository {
  final BaseSubGroupDataSource _remote;
  final SubGroupLocalDataSourceImpl _local;
  final SyncService _syncService;

  SubGroupRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
    this._syncService,
  );

  @override
  Future<Either<Failure, PaginatedResult<SubGroup>>> getSubGroups({
    required int groupId,
    String? search,
    required int pageIndex,
    required int pageSize,
  }) async {
    final result = await _remote.getSubGroups(
      groupId: groupId,
      search: search,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
    return result.fold(Left.new, (response) => Right(response.toResult((r) => r.toEntity())));
  }

  @override
  Stream<List<SubGroup>> watchSubGroups({required int groupId, String? search, required int limit}) =>
      _local.watchSubGroups(groupId: groupId, search: search, limit: limit);

  @override
  Future<int> countSubGroups({required int groupId, String? search}) =>
      _local.countSubGroups(groupId: groupId, search: search);

  int _newTempSubGroupId() => -DateTime.now().microsecondsSinceEpoch;

  /// Builds the [SubGroup] draft + JSON-encoded create payload (groupId
  /// included alongside the request body — `CreateSubGroupRequest.toJson()`
  /// omits it since it's normally routed, but `SubGroupOutboxReplayer` needs
  /// it to call `BaseSubGroupDataSource.createSubGroup(groupId, ...)`) and
  /// queues both via the outbox. Shared by [createSubGroup] and
  /// [createSubGroupAndSync].
  Future<(SubGroup, int)> _queueCreate({required int groupId, required String name, String? nameAr}) async {
    final subGroup = SubGroup(id: _newTempSubGroupId(), groupId: groupId, name: name, nameAr: nameAr);
    final payloadJson = jsonEncode({
      'groupId': groupId,
      ...CreateSubGroupRequest(name: name, nameAr: nameAr).toJson(),
    });
    final rowId =
        await _local.queueSubGroupMutation(subGroup: subGroup, operation: 'create', payloadJson: payloadJson);
    return (subGroup, rowId);
  }

  @override
  Future<Either<Failure, SubGroup>> createSubGroup({
    required int groupId,
    required String name,
    String? nameAr,
  }) async {
    final (subGroup, _) = await _queueCreate(groupId: groupId, name: name, nameAr: nameAr);
    return Right(subGroup);
  }

  @override
  Future<Either<Failure, SubGroup>> createSubGroupAndSync({
    required int groupId,
    required String name,
    String? nameAr,
  }) async {
    final (subGroup, rowId) = await _queueCreate(groupId: groupId, name: name, nameAr: nameAr);
    final result = await _syncService.replayRow(rowId);
    return result.fold(Left.new, (payload) => Right(payload as SubGroup? ?? subGroup));
  }

  @override
  Future<Either<Failure, SubGroup>> updateSubGroup({
    required int groupId,
    required int id,
    required String name,
    String? nameAr,
  }) async {
    final subGroup = SubGroup(id: id, groupId: groupId, name: name, nameAr: nameAr);
    final payloadJson = jsonEncode({
      'groupId': groupId,
      ...UpdateSubGroupRequest(name: name, nameAr: nameAr).toJson(),
    });
    await _local.queueSubGroupMutation(subGroup: subGroup, operation: 'update', payloadJson: payloadJson);
    return Right(subGroup);
  }

  @override
  Future<Either<Failure, Unit>> deleteSubGroup({required int groupId, required int id}) async {
    await _local.queueDeletedSubGroup(id, payloadJson: jsonEncode({'groupId': groupId}));
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> refreshSubGroups() async {
    const pageSize = 200;
    // Defensive cap against a pathological `hasMore` loop — this data shape
    // is meant to be small (a user's own custom subgroups), never expected
    // to trip.
    const maxPages = 50;
    var cursor = await _local.getSubGroupsSyncCursor();
    for (var page = 0; page < maxPages; page++) {
      final result = await _remote.getSubGroupChanges(since: cursor, pageSize: pageSize);
      if (result.isLeft()) {
        return result.fold(Left.new, (_) => throw StateError('unreachable'));
      }
      final changes = result.getOrElse(() => throw StateError('unreachable'));
      await _local.applySubGroupChanges(
        upserts: changes.upserts.map((r) => r.toEntity()).toList(),
        tombstoneIds: changes.tombstoneIds,
      );
      await _local.saveSubGroupsSyncCursor(changes.cursor);
      cursor = changes.cursor;
      if (!changes.hasMore) break;
    }
    return const Right(unit);
  }
}

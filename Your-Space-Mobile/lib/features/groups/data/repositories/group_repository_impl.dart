import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import '../../domain/repositories/base_group_repository.dart';
import '../datasources/base_group_data_source.dart';
import '../datasources/group_local_data_source_impl.dart';
import '../models/create_group_request.dart';
import '../models/update_group_request.dart';

@LazySingleton(as: GroupRepository)
class GroupRepositoryImpl implements GroupRepository {
  final BaseGroupDataSource _remote;
  final GroupLocalDataSourceImpl _local;
  final SyncService _syncService;

  GroupRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
    this._syncService,
  );

  @override
  Future<Either<Failure, PaginatedResult<Group>>> getGroups({
    String? search,
    required int pageIndex,
    required int pageSize,
  }) async {
    final result = await _remote.getGroups(search: search, pageIndex: pageIndex, pageSize: pageSize);
    return result.fold(Left.new, (response) => Right(response.toResult((r) => r.toEntity())));
  }

  @override
  Stream<List<Group>> watchGroups({String? search, required int limit}) =>
      _local.watchGroups(search: search, limit: limit);

  @override
  Future<int> countGroups({String? search}) => _local.countGroups(search: search);

  @override
  Future<Either<Failure, Unit>> refreshGroups() async {
    const pageSize = 200;
    // Defensive cap against a pathological `hasMore` loop — this data shape
    // is meant to be small (design doc §1/§2: Groups is "small, low
    // cardinality"), never expected to trip.
    const maxPages = 50;
    var cursor = await _local.getGroupsSyncCursor();
    for (var page = 0; page < maxPages; page++) {
      final result = await _remote.getGroupChanges(since: cursor, pageSize: pageSize);
      if (result.isLeft()) {
        return result.fold(Left.new, (_) => throw StateError('unreachable'));
      }
      final changes = result.getOrElse(() => throw StateError('unreachable'));
      await _local.applyGroupChanges(
        upserts: changes.upserts.map((r) => r.toEntity()).toList(),
        tombstoneIds: changes.tombstoneIds,
      );
      await _local.saveGroupsSyncCursor(changes.cursor);
      cursor = changes.cursor;
      if (!changes.hasMore) break;
    }
    return const Right(unit);
  }

  int _newTempGroupId() => -DateTime.now().microsecondsSinceEpoch;

  /// Builds the [Group] draft + JSON-encoded [CreateGroupRequest] payload
  /// and queues both via the outbox. Shared by [createGroup] and
  /// [createGroupAndSync] — only what happens after queuing differs.
  Future<(Group, int)> _queueCreate({required String name, String? nameAr}) async {
    final group = Group(id: _newTempGroupId(), name: name, nameAr: nameAr);
    final payloadJson = jsonEncode(CreateGroupRequest(name: name, nameAr: nameAr).toJson());
    final rowId = await _local.queueGroupMutation(group: group, operation: 'create', payloadJson: payloadJson);
    return (group, rowId);
  }

  @override
  Future<Either<Failure, Group>> createGroup({required String name, String? nameAr}) async {
    final (group, _) = await _queueCreate(name: name, nameAr: nameAr);
    return Right(group);
  }

  @override
  Future<Either<Failure, Group>> createGroupAndSync({required String name, String? nameAr}) async {
    final (group, rowId) = await _queueCreate(name: name, nameAr: nameAr);
    final result = await _syncService.replayRow(rowId);
    return result.fold(Left.new, (payload) => Right(payload as Group? ?? group));
  }

  @override
  Future<Either<Failure, Group>> updateGroup({
    required int id,
    required String name,
    String? nameAr,
  }) async {
    final group = Group(id: id, name: name, nameAr: nameAr);
    final payloadJson = jsonEncode(UpdateGroupRequest(id: id, name: name, nameAr: nameAr).toJson());
    await _local.queueGroupMutation(group: group, operation: 'update', payloadJson: payloadJson);
    return Right(group);
  }
}

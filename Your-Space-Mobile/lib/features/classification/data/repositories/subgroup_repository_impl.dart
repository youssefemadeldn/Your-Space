import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/repositories/base_subgroup_repository.dart';
import '../datasources/base_subgroup_data_source.dart';
import '../datasources/subgroup_local_data_source_impl.dart';
import '../models/create_subgroup_request.dart';
import '../models/update_subgroup_request.dart';

@LazySingleton(as: SubGroupRepository)
class SubGroupRepositoryImpl implements SubGroupRepository {
  final BaseSubGroupDataSource _remote;
  final SubGroupLocalDataSourceImpl _local;

  SubGroupRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
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

  @override
  Future<Either<Failure, SubGroup>> createSubGroup({
    required int groupId,
    required String name,
    String? nameAr,
  }) async {
    final result = await _remote.createSubGroup(groupId, CreateSubGroupRequest(name: name, nameAr: nameAr));
    if (result.isLeft()) return result.fold(Left.new, (_) => throw StateError('unreachable'));
    final subGroup = result.getOrElse(() => throw StateError('unreachable')).toEntity();
    // Transitional Tier 1 write path (design doc §3) — superseded by the
    // outbox once row 8.15 lands. Upserting on success keeps the local cache
    // from going stale until the next Tier 3 pull.
    await _local.saveSubGroup(subGroup);
    return Right(subGroup);
  }

  @override
  Future<Either<Failure, SubGroup>> updateSubGroup({
    required int groupId,
    required int id,
    required String name,
    String? nameAr,
  }) async {
    final result =
        await _remote.updateSubGroup(groupId, id, UpdateSubGroupRequest(name: name, nameAr: nameAr));
    if (result.isLeft()) return result.fold(Left.new, (_) => throw StateError('unreachable'));
    final subGroup = result.getOrElse(() => throw StateError('unreachable')).toEntity();
    await _local.saveSubGroup(subGroup);
    return Right(subGroup);
  }

  @override
  Future<Either<Failure, Unit>> deleteSubGroup({required int groupId, required int id}) async {
    final result = await _remote.deleteSubGroup(groupId, id);
    if (result.isLeft()) return result;
    await _local.deleteSubGroupLocal(id);
    return result;
  }
}

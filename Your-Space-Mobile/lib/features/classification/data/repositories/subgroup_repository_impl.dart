import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/repositories/base_subgroup_repository.dart';
import '../datasources/subgroup_remote_data_source_impl.dart';
import '../models/create_subgroup_request.dart';
import '../models/update_subgroup_request.dart';

@LazySingleton(as: SubGroupRepository)
class SubGroupRepositoryImpl implements SubGroupRepository {
  final SubGroupRemoteDataSourceImpl _remote;

  SubGroupRepositoryImpl(this._remote);

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
  Future<Either<Failure, SubGroup>> createSubGroup({
    required int groupId,
    required String name,
    String? nameAr,
  }) async {
    final result = await _remote.createSubGroup(groupId, CreateSubGroupRequest(name: name, nameAr: nameAr));
    return result.fold(Left.new, (response) => Right(response.toEntity()));
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
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, Unit>> deleteSubGroup({required int groupId, required int id}) =>
      _remote.deleteSubGroup(groupId, id);
}

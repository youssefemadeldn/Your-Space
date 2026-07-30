import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/repositories/base_group_repository.dart';
import '../datasources/group_remote_data_source_impl.dart';
import '../models/create_group_request.dart';
import '../models/update_group_request.dart';

@LazySingleton(as: GroupRepository)
class GroupRepositoryImpl implements GroupRepository {
  final GroupRemoteDataSourceImpl _remote;

  GroupRepositoryImpl(this._remote);

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
  Future<Either<Failure, Group>> createGroup({required String name, String? nameAr}) async {
    final result = await _remote.createGroup(CreateGroupRequest(name: name, nameAr: nameAr));
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, Group>> updateGroup({
    required int id,
    required String name,
    String? nameAr,
  }) async {
    final result = await _remote.updateGroup(UpdateGroupRequest(id: id, name: name, nameAr: nameAr));
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }
}

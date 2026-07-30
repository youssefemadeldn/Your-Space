import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/constants/api_constants.dart';
import 'package:your_space_mobile/core/network/api_envelope.dart';
import 'package:your_space_mobile/core/network/api_manager.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/create_group_request.dart';
import '../models/group_response.dart';
import '../models/update_group_request.dart';

@lazySingleton
class GroupRemoteDataSourceImpl {
  final ApiManager _api;

  GroupRemoteDataSourceImpl(this._api);

  Future<Either<Failure, PaginatedResponse<GroupResponse>>> getGroups({
    String? search,
    required int pageIndex,
    required int pageSize,
  }) =>
      _api.get<PaginatedResponse<GroupResponse>>(
        path: ApiConstants.groups,
        queryParameters: {
          'search': ?search,
          'pageIndex': pageIndex,
          'pageSize': pageSize,
        },
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PaginatedResponse.fromJson(
            inner as Map<String, dynamic>,
            (item) => GroupResponse.fromJson(item as Map<String, dynamic>),
          ),
        ),
      );

  Future<Either<Failure, GroupResponse>> createGroup(CreateGroupRequest request) =>
      _api.post<GroupResponse>(
        path: ApiConstants.groups,
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => GroupResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, GroupResponse>> updateGroup(UpdateGroupRequest request) =>
      _api.put<GroupResponse>(
        path: ApiConstants.groups,
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => GroupResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );
}

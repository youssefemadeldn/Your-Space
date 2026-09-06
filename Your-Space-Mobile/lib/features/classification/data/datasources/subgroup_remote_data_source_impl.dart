import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/constants/api_constants.dart';
import 'package:your_space_mobile/core/network/api_envelope.dart';
import 'package:your_space_mobile/core/network/api_manager.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/create_subgroup_request.dart';
import '../models/subgroup_response.dart';
import '../models/update_subgroup_request.dart';

@lazySingleton
class SubGroupRemoteDataSourceImpl {
  final ApiManager _api;

  SubGroupRemoteDataSourceImpl(this._api);

  String _basePath(int groupId) => '${ApiConstants.groups}/$groupId/${ApiConstants.subgroupsSegment}';

  Future<Either<Failure, PaginatedResponse<SubGroupResponse>>> getSubGroups({
    required int groupId,
    String? search,
    required int pageIndex,
    required int pageSize,
  }) =>
      _api.get<PaginatedResponse<SubGroupResponse>>(
        path: _basePath(groupId),
        queryParameters: {'search': ?search, 'pageIndex': pageIndex, 'pageSize': pageSize},
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PaginatedResponse.fromJson(
            inner as Map<String, dynamic>,
            (item) => SubGroupResponse.fromJson(item as Map<String, dynamic>),
          ),
        ),
      );

  Future<Either<Failure, SubGroupResponse>> createSubGroup(int groupId, CreateSubGroupRequest request) =>
      _api.post<SubGroupResponse>(
        path: _basePath(groupId),
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => SubGroupResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, SubGroupResponse>> updateSubGroup(int groupId, int id, UpdateSubGroupRequest request) =>
      _api.put<SubGroupResponse>(
        path: '${_basePath(groupId)}/$id',
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => SubGroupResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, Unit>> deleteSubGroup(int groupId, int id) => _api.delete<Unit>(
        path: '${_basePath(groupId)}/$id',
        fromJson: (_) => unit,
      );
}

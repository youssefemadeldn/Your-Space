import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/constants/api_constants.dart';
import 'package:your_space_mobile/core/network/api_envelope.dart';
import 'package:your_space_mobile/core/network/api_manager.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/create_governorate_request.dart';
import '../models/governorate_changes_response.dart';
import '../models/governorate_response.dart';
import 'base_governorate_data_source.dart';

@Named('remote')
@LazySingleton(as: BaseGovernorateDataSource)
class GovernorateRemoteDataSourceImpl implements BaseGovernorateDataSource {
  final ApiManager _api;

  GovernorateRemoteDataSourceImpl(this._api);

  @override
  Future<Either<Failure, PaginatedResponse<GovernorateResponse>>> getGovernorates({
    String? search,
    required int pageIndex,
    required int pageSize,
  }) =>
      _api.get<PaginatedResponse<GovernorateResponse>>(
        path: ApiConstants.governorates,
        queryParameters: {'search': ?search, 'pageIndex': pageIndex, 'pageSize': pageSize},
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PaginatedResponse.fromJson(
            inner as Map<String, dynamic>,
            (item) => GovernorateResponse.fromJson(item as Map<String, dynamic>),
          ),
        ),
      );

  @override
  Future<Either<Failure, GovernorateResponse>> createGovernorate(CreateGovernorateRequest request) =>
      _api.post<GovernorateResponse>(
        path: ApiConstants.governorates,
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => GovernorateResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  @override
  Future<Either<Failure, GovernorateChangesResponse>> getGovernorateChanges({
    required int since,
    required int pageSize,
  }) =>
      _api.get<GovernorateChangesResponse>(
        path: '${ApiConstants.governorates}/changes',
        queryParameters: {
          'since': since,
          'pageSize': pageSize,
        },
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => GovernorateChangesResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );
}

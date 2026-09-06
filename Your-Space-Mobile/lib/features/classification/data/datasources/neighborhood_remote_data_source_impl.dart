import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/constants/api_constants.dart';
import 'package:your_space_mobile/core/network/api_envelope.dart';
import 'package:your_space_mobile/core/network/api_manager.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/create_neighborhood_request.dart';
import '../models/neighborhood_response.dart';
import '../models/update_neighborhood_request.dart';

@lazySingleton
class NeighborhoodRemoteDataSourceImpl {
  final ApiManager _api;

  NeighborhoodRemoteDataSourceImpl(this._api);

  // NeighborhoodsController is nested directly under /cities/{cityId} — a
  // top-level path segment, not under City's own /governorates/{id}/cities.
  String _basePath(int cityId) => '/${ApiConstants.citiesSegment}/$cityId/${ApiConstants.neighborhoodsSegment}';

  Future<Either<Failure, PaginatedResponse<NeighborhoodResponse>>> getNeighborhoods({
    required int cityId,
    String? search,
    required int pageIndex,
    required int pageSize,
  }) =>
      _api.get<PaginatedResponse<NeighborhoodResponse>>(
        path: _basePath(cityId),
        queryParameters: {'search': ?search, 'pageIndex': pageIndex, 'pageSize': pageSize},
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PaginatedResponse.fromJson(
            inner as Map<String, dynamic>,
            (item) => NeighborhoodResponse.fromJson(item as Map<String, dynamic>),
          ),
        ),
      );

  Future<Either<Failure, NeighborhoodResponse>> createNeighborhood(
    int cityId,
    CreateNeighborhoodRequest request,
  ) =>
      _api.post<NeighborhoodResponse>(
        path: _basePath(cityId),
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => NeighborhoodResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, NeighborhoodResponse>> updateNeighborhood(
    int cityId,
    int id,
    UpdateNeighborhoodRequest request,
  ) =>
      _api.put<NeighborhoodResponse>(
        path: '${_basePath(cityId)}/$id',
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => NeighborhoodResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, Unit>> deleteNeighborhood(int cityId, int id) => _api.delete<Unit>(
        path: '${_basePath(cityId)}/$id',
        fromJson: (_) => unit,
      );
}

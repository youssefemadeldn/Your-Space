import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/constants/api_constants.dart';
import 'package:your_space_mobile/core/network/api_envelope.dart';
import 'package:your_space_mobile/core/network/api_manager.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/city_response.dart';
import '../models/create_city_request.dart';
import '../models/update_city_request.dart';

@lazySingleton
class CityRemoteDataSourceImpl {
  final ApiManager _api;

  CityRemoteDataSourceImpl(this._api);

  String _basePath(int governorateId) =>
      '${ApiConstants.governorates}/$governorateId/${ApiConstants.citiesSegment}';

  Future<Either<Failure, PaginatedResponse<CityResponse>>> getCities({
    required int governorateId,
    String? search,
    required int pageIndex,
    required int pageSize,
  }) =>
      _api.get<PaginatedResponse<CityResponse>>(
        path: _basePath(governorateId),
        queryParameters: {'search': ?search, 'pageIndex': pageIndex, 'pageSize': pageSize},
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PaginatedResponse.fromJson(
            inner as Map<String, dynamic>,
            (item) => CityResponse.fromJson(item as Map<String, dynamic>),
          ),
        ),
      );

  Future<Either<Failure, CityResponse>> createCity(int governorateId, CreateCityRequest request) =>
      _api.post<CityResponse>(
        path: _basePath(governorateId),
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => CityResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, CityResponse>> updateCity(int governorateId, int id, UpdateCityRequest request) =>
      _api.put<CityResponse>(
        path: '${_basePath(governorateId)}/$id',
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => CityResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, Unit>> deleteCity(int governorateId, int id) => _api.delete<Unit>(
        path: '${_basePath(governorateId)}/$id',
        fromJson: (_) => unit,
      );
}

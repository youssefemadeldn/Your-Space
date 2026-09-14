import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/city_response.dart';
import '../models/create_city_request.dart';
import '../models/update_city_request.dart';

/// Contract for `CityRepositoryImpl`'s remote dependency, mirrors
/// `BaseGovernorateDataSource`. City's first abstract data-source seam — the
/// concrete `CityRemoteDataSourceImpl` was previously injected directly.
///
/// Mirrors the remote data source's full surface, not just reads: this seam
/// exists so `CityRepositoryImpl` and (from row 8.9 onward)
/// `CityOutboxReplayer` can depend on an abstraction rather than the
/// concrete `CityRemoteDataSourceImpl`. `CityLocalDataSourceImpl` does not
/// implement this contract; it's a separate, concrete local surface.
abstract class BaseCityDataSource {
  Future<Either<Failure, PaginatedResponse<CityResponse>>> getCities({
    required int governorateId,
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  /// Flat "all mine" pull (row 8.8) — governorate-agnostic, feeds Tier 1's
  /// bulk local population and (from row 8.10) the interim full-refetch pull.
  Future<Either<Failure, PaginatedResponse<CityResponse>>> getAllMineCities({
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, CityResponse>> createCity(int governorateId, CreateCityRequest request);

  Future<Either<Failure, CityResponse>> updateCity(int governorateId, int id, UpdateCityRequest request);

  Future<Either<Failure, Unit>> deleteCity(int governorateId, int id);
}

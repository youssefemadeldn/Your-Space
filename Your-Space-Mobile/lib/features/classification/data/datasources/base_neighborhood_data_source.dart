import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/create_neighborhood_request.dart';
import '../models/neighborhood_changes_response.dart';
import '../models/neighborhood_response.dart';
import '../models/update_neighborhood_request.dart';

/// Contract for `NeighborhoodRepositoryImpl`'s remote dependency, mirrors
/// `BaseSubGroupDataSource`. Neighborhood's first abstract data-source seam —
/// the concrete `NeighborhoodRemoteDataSourceImpl` was previously injected
/// directly.
///
/// Mirrors the remote data source's full surface, not just reads: this seam
/// exists so `NeighborhoodRepositoryImpl` (and, from a later row, a
/// `NeighborhoodOutboxReplayer`) can depend on an abstraction rather than the
/// concrete `NeighborhoodRemoteDataSourceImpl`. `NeighborhoodLocalDataSourceImpl`
/// does not implement this contract; it's a separate, concrete local surface.
abstract class BaseNeighborhoodDataSource {
  Future<Either<Failure, PaginatedResponse<NeighborhoodResponse>>> getNeighborhoods({
    required int cityId,
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  /// Flat "all mine" pull (row 8.20) — city-agnostic, feeds Tier 1's bulk
  /// local population.
  Future<Either<Failure, PaginatedResponse<NeighborhoodResponse>>> getAllMineNeighborhoods({
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, NeighborhoodResponse>> createNeighborhood(int cityId, CreateNeighborhoodRequest request);

  Future<Either<Failure, NeighborhoodResponse>> updateNeighborhood(
    int cityId,
    int id,
    UpdateNeighborhoodRequest request,
  );

  Future<Either<Failure, Unit>> deleteNeighborhood(int cityId, int id);

  /// Tier 3 real delta pull (design doc §6, row 8.24): [since] is the last
  /// cursor seen (0 on first sync); the response's `hasMore` tells the
  /// caller whether to keep paging with the returned `cursor` as the next
  /// `since`.
  Future<Either<Failure, NeighborhoodChangesResponse>> getNeighborhoodChanges({
    required int since,
    required int pageSize,
  });
}

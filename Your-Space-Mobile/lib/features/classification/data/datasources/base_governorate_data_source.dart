import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/create_governorate_request.dart';
import '../models/governorate_changes_response.dart';
import '../models/governorate_response.dart';

/// Contract for `GovernorateRepositoryImpl`'s remote dependency, mirrors
/// `BaseGroupDataSource`.
///
/// Mirrors the remote data source's full surface, not just reads: this seam
/// exists so `GovernorateRepositoryImpl` and (from row 8.3 onward)
/// `GovernorateOutboxReplayer` can depend on an abstraction rather than the
/// concrete `GovernorateRemoteDataSourceImpl`. `GovernorateLocalDataSourceImpl`
/// does not implement this contract; it's a separate, concrete local surface.
abstract class BaseGovernorateDataSource {
  Future<Either<Failure, PaginatedResponse<GovernorateResponse>>> getGovernorates({
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, GovernorateResponse>> createGovernorate(CreateGovernorateRequest request);

  /// Tier 3 real delta pull (design doc §6, row 8.6): [since] is the last
  /// cursor seen (0 on first sync); the response's `hasMore` tells the
  /// caller whether to keep paging with the returned `cursor` as the next
  /// `since`.
  Future<Either<Failure, GovernorateChangesResponse>> getGovernorateChanges({
    required int since,
    required int pageSize,
  });
}

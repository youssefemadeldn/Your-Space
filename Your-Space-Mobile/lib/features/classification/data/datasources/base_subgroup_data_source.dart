import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/create_subgroup_request.dart';
import '../models/subgroup_response.dart';
import '../models/update_subgroup_request.dart';

/// Contract for `SubGroupRepositoryImpl`'s remote dependency, mirrors
/// `BaseCityDataSource`. SubGroup's first abstract data-source seam — the
/// concrete `SubGroupRemoteDataSourceImpl` was previously injected directly.
///
/// Mirrors the remote data source's full surface, not just reads: this seam
/// exists so `SubGroupRepositoryImpl` and (from row 8.15 onward)
/// `SubGroupOutboxReplayer` can depend on an abstraction rather than the
/// concrete `SubGroupRemoteDataSourceImpl`. `SubGroupLocalDataSourceImpl` does
/// not implement this contract; it's a separate, concrete local surface.
abstract class BaseSubGroupDataSource {
  Future<Either<Failure, PaginatedResponse<SubGroupResponse>>> getSubGroups({
    required int groupId,
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  /// Flat "all mine" pull (row 8.14) — group-agnostic, feeds Tier 1's bulk
  /// local population and (from row 8.16) the interim full-refetch pull.
  Future<Either<Failure, PaginatedResponse<SubGroupResponse>>> getAllMineSubGroups({
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, SubGroupResponse>> createSubGroup(int groupId, CreateSubGroupRequest request);

  Future<Either<Failure, SubGroupResponse>> updateSubGroup(int groupId, int id, UpdateSubGroupRequest request);

  Future<Either<Failure, Unit>> deleteSubGroup(int groupId, int id);
}

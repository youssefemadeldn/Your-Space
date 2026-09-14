import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/create_group_request.dart';
import '../models/group_changes_response.dart';
import '../models/group_response.dart';
import '../models/update_group_request.dart';

/// Contract for `GroupRepositoryImpl`'s remote dependency, mirrors
/// `BasePersonDataSource`.
///
/// This mirrors the remote data source's full surface, not just reads:
/// injectable's `@LazySingleton(as: X)` registers the instance only under
/// `X` — so every method a caller needs from `_remote` (the repository, and
/// now `GroupOutboxReplayer`) has to be reachable through this interface.
/// `GroupLocalDataSourceImpl` does not implement this contract; it's a
/// separate, concrete local surface.
abstract class BaseGroupDataSource {
  Future<Either<Failure, PaginatedResponse<GroupResponse>>> getGroups({
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, GroupResponse>> createGroup(CreateGroupRequest request);

  Future<Either<Failure, GroupResponse>> updateGroup(UpdateGroupRequest request);

  /// Tier 3 real delta pull (design doc §6, row 7.6): [since] is the last
  /// cursor seen (0 on first sync); the response's `hasMore` tells the
  /// caller whether to keep paging with the returned `cursor` as the next
  /// `since`.
  Future<Either<Failure, GroupChangesResponse>> getGroupChanges({
    required int since,
    required int pageSize,
  });
}

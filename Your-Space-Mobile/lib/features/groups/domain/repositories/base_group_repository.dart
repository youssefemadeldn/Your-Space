import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';

abstract class GroupRepository {
  Future<Either<Failure, PaginatedResult<Group>>> getGroups({
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  /// Tier 1 read path for `GroupsListCubit`/`PersonWizardCubit` (local-first,
  /// CLAUDE.md rule 7) — reads local drift only, never touches the network.
  /// `limit` grows as `loadMore()` is called; the caller resubscribes rather
  /// than tracking an offset (see `doc/local-first-sync-design.md` §3).
  Stream<List<Group>> watchGroups({String? search, required int limit});

  /// One-shot exact count for the same filter set, local-only — backs
  /// `hasNextPage` without a `length == limit` heuristic.
  Future<int> countGroups({String? search});

  Future<Either<Failure, Group>> createGroup({required String name, String? nameAr});

  Future<Either<Failure, Group>> updateGroup({
    required int id,
    required String name,
    String? nameAr,
  });
}

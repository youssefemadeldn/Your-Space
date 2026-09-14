import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/network/failure.dart';

abstract class SubGroupRepository {
  Future<Either<Failure, PaginatedResult<SubGroup>>> getSubGroups({
    required int groupId,
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  /// Tier 1 read path for `SubGroupListCubit`/`PersonWizardCubit`/
  /// `PeopleListCubit`/`AddGuestsListCubit` (local-first, CLAUDE.md rule 7)
  /// — reads local drift only, never touches the network. `limit` grows as
  /// `loadMore()` is called; the caller resubscribes rather than tracking an
  /// offset (see `doc/local-first-sync-design.md` §3).
  Stream<List<SubGroup>> watchSubGroups({required int groupId, String? search, required int limit});

  /// One-shot exact count for the same filter set, local-only — backs
  /// `hasNextPage` without a `length == limit` heuristic.
  Future<int> countSubGroups({required int groupId, String? search});

  Future<Either<Failure, SubGroup>> createSubGroup({required int groupId, required String name, String? nameAr});

  Future<Either<Failure, SubGroup>> updateSubGroup({
    required int groupId,
    required int id,
    required String name,
    String? nameAr,
  });

  Future<Either<Failure, Unit>> deleteSubGroup({required int groupId, required int id});
}

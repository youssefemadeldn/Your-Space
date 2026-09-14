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

  /// Queues the create and immediately asks `SyncService` to replay it, so
  /// the caller gets back a real, server-confirmed id (or a failure) rather
  /// than an optimistic temp id — for offline inline-add chains (e.g. the
  /// wizard's "add new subgroup" affordance) that embed the returned id
  /// directly into another entity's own payload, where reconciliation can't
  /// reach it. Mirrors `CityRepository.createCityAndSync`.
  Future<Either<Failure, SubGroup>> createSubGroupAndSync({
    required int groupId,
    required String name,
    String? nameAr,
  });

  Future<Either<Failure, SubGroup>> updateSubGroup({
    required int groupId,
    required int id,
    required String name,
    String? nameAr,
  });

  Future<Either<Failure, Unit>> deleteSubGroup({required int groupId, required int id});

  /// Tier 3 interim pull (design doc §6, row 8.16): fetches every page of the
  /// caller's own subgroups via the flat `GET /subgroups` endpoint and
  /// reconciles them into the local drift store via `applySubGroupsSnapshot`.
  /// Superseded by a real cursor-based delta once row 8.18 lands. Mirrors
  /// `CityRepository.refreshCities()`.
  Future<Either<Failure, Unit>> refreshSubGroups();
}

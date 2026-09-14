import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';

abstract class CityRepository {
  Future<Either<Failure, PaginatedResult<City>>> getCities({
    required int governorateId,
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  /// Tier 1 read path for `CityListCubit`/`PersonWizardCubit`/
  /// `PeopleListCubit`/`AddGuestsListCubit` (local-first, CLAUDE.md rule 7)
  /// — reads local drift only, never touches the network. `limit` grows as
  /// `loadMore()` is called; the caller resubscribes rather than tracking an
  /// offset (see `doc/local-first-sync-design.md` §3).
  Stream<List<City>> watchCities({required int governorateId, String? search, required int limit});

  /// One-shot exact count for the same filter set, local-only — backs
  /// `hasNextPage` without a `length == limit` heuristic.
  Future<int> countCities({required int governorateId, String? search});

  /// Tier 3 background pull (design doc §6, row 8.10) — "full refetch as
  /// delta" interim mode, since the backend has no `since`/cursor support
  /// for City yet (that lands in 8.11/8.12). Called by `CityCollectionPuller`
  /// from `SyncService`'s background pull cadence, never awaited from a
  /// cubit or screen. Mirrors `GovernorateRepository.refreshGovernorates()`'s
  /// own pre-8.6 interim shape.
  Future<Either<Failure, Unit>> refreshCities();

  Future<Either<Failure, City>> createCity({required int governorateId, required String name, String? nameAr});

  /// Queues the create and immediately asks `SyncService` to replay it, so
  /// the caller gets back a real, server-confirmed id (or a failure) rather
  /// than an optimistic temp id — for offline inline-add chains (e.g. the
  /// wizard's "add new city" affordance) that embed the returned id directly
  /// into another entity's own payload, where reconciliation can't reach it.
  /// Mirrors `GroupRepository.createGroupAndSync`.
  Future<Either<Failure, City>> createCityAndSync({
    required int governorateId,
    required String name,
    String? nameAr,
  });

  Future<Either<Failure, City>> updateCity({
    required int governorateId,
    required int id,
    required String name,
    String? nameAr,
  });

  Future<Either<Failure, Unit>> deleteCity({required int governorateId, required int id});
}

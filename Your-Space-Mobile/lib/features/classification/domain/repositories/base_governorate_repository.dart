import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';

/// No update/delete — Governorate has no dedicated management screen, per
/// the locked spec's confirmed asymmetry (users can create custom
/// governorates via the wizard's inline "+ Add new" but never rename/delete
/// them from mobile this sprint).
abstract class GovernorateRepository {
  Future<Either<Failure, PaginatedResult<Governorate>>> getGovernorates({
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  /// Tier 1 read path for `PersonWizardCubit`/`PeopleListCubit`/
  /// `AddGuestsListCubit` (local-first, CLAUDE.md rule 7) — reads local drift
  /// only, never touches the network. `limit` grows as `loadMore()` is
  /// called; the caller resubscribes rather than tracking an offset (see
  /// `doc/local-first-sync-design.md` §3).
  Stream<List<Governorate>> watchGovernorates({String? search, required int limit});

  /// One-shot exact count for the same filter set, local-only — backs
  /// `hasNextPage` without a `length == limit` heuristic.
  Future<int> countGovernorates({String? search});

  Future<Either<Failure, Governorate>> createGovernorate({required String name, String? nameAr});
}

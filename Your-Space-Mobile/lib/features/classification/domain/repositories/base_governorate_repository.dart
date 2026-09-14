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

  /// Tier 3 "full refetch as delta" interim pull (design doc §6, row 8.4):
  /// no backend `since`/cursor support exists for Governorate yet, so this
  /// loops the paginated remote endpoint until exhausted and diffs the
  /// result against local drift by absence (mirrors
  /// `GroupRepository.refreshGroups()`'s pre-row-7.6 shape). Superseded by a
  /// real delta pull once row 8.5/8.6 add backend `SyncVersion`/
  /// `GET /governorates/changes` support. The result only signals whether
  /// the fetch itself succeeded — on failure the UI keeps showing cached
  /// data (design doc §3).
  Future<Either<Failure, Unit>> refreshGovernorates();

  /// Tier 2 optimistic write (design doc §5): queues via the outbox and
  /// returns immediately with a temp id. Essentially can't fail — a drift
  /// write isn't gated on connectivity.
  Future<Either<Failure, Governorate>> createGovernorate({required String name, String? nameAr});

  /// Same as [createGovernorate] but also asks `SyncService` to replay this
  /// specific outbox row immediately and awaits the outcome (awaited here,
  /// in the repository/data layer — never by a cubit, per CLAUDE.md's
  /// DI-scopes table). `Right(Governorate)` means the governorate now has a
  /// real server id. `Left(failure)` means the immediate sync attempt
  /// failed right now (offline/server error) — the queued row is NOT rolled
  /// back and will still sync in the background later, but this call
  /// reports failure so callers needing a synchronously-resolved real id
  /// (the person wizard's inline "add new governorate", which embeds the id
  /// in the person's own create/update payload) can fail cleanly instead of
  /// silently proceeding against a temp id. Mirrors
  /// `GroupRepository.createGroupAndSync` — no `updateGovernorateAndSync`
  /// exists for the same reason no `updateGroupAndSync` does: Governorate
  /// has no update path at all.
  Future<Either<Failure, Governorate>> createGovernorateAndSync({required String name, String? nameAr});
}

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

  /// Tier 3 "full refetch as delta" interim pull (design doc §6, row 7.4):
  /// no backend `since`/cursor support exists for Group yet, so this loops
  /// the paginated remote endpoint until exhausted and diffs the result
  /// against local drift by absence (mirrors `PersonRepository.refreshPersons()`'s
  /// pre-row-6 shape). Superseded by a real delta pull once row 7.5/7.6 add
  /// backend `SyncVersion`/`GET /groups/changes` support. The result only
  /// signals whether the fetch itself succeeded — on failure the UI keeps
  /// showing cached data (design doc §3).
  Future<Either<Failure, Unit>> refreshGroups();

  /// Tier 2 optimistic write (design doc §5): queues via the outbox and
  /// returns immediately with a temp id. Essentially can't fail — a drift
  /// write isn't gated on connectivity.
  Future<Either<Failure, Group>> createGroup({required String name, String? nameAr});

  Future<Either<Failure, Group>> updateGroup({
    required int id,
    required String name,
    String? nameAr,
  });

  /// Same as [createGroup] but also asks `SyncService` to replay this
  /// specific outbox row immediately and awaits the outcome (awaited here,
  /// in the repository/data layer — never by a cubit, per CLAUDE.md's
  /// DI-scopes table). `Right(Group)` means the group now has a real server
  /// id. `Left(failure)` means the immediate sync attempt failed right now
  /// (offline/server error) — the queued row is NOT rolled back and will
  /// still sync in the background later, but this call reports failure so
  /// callers needing a synchronously-resolved real id (the person wizard's
  /// inline "add new group", which embeds the id in the person's own
  /// create/update payload) can fail cleanly instead of silently proceeding
  /// against a temp id. No `updateGroupAndSync` exists — nothing in scope
  /// needs a synchronous id resolution after an *edit*, only after a create.
  Future<Either<Failure, Group>> createGroupAndSync({required String name, String? nameAr});
}

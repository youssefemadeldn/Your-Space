import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';

import '../entities/person_details.dart';
import '../entities/person_occasion_history_entry.dart';

abstract class PersonRepository {
  Future<Either<Failure, PaginatedResult<Person>>> getPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, PersonDetails>> getPersonById(int id);

  /// Tier 1 read path for `PeopleListCubit` (local-first, CLAUDE.md rule 7) —
  /// reads local drift only, never touches the network. `limit` grows as
  /// `loadMore()` is called; the caller resubscribes rather than tracking an
  /// offset (see `doc/local-first-sync-design.md` §3).
  Stream<List<Person>> watchPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
    required int limit,
  });

  /// One-shot exact count for the same filter set, local-only — backs
  /// `hasNextPage` without a `length == limit` heuristic.
  Future<int> countPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
  });

  /// Tier 3 real delta pull (design doc §6, row 6): loops the backend's
  /// cursor-based `/persons/changes` endpoint against the stored watermark
  /// until `hasMore` is false, applying each page's upserts/tombstones and
  /// persisting the advancing cursor after every page. The result only
  /// signals whether the fetch itself succeeded — on failure the UI keeps
  /// showing cached data (design doc §3).
  Future<Either<Failure, Unit>> refreshPersons();

  /// Tier 2 optimistic write (design doc §5): queues via the outbox and
  /// returns immediately with a temp id. Essentially can't fail — a drift
  /// write isn't gated on connectivity. Use for mutations with no dependent
  /// network call that needs a resolved real id synchronously.
  ///
  /// `groupName`/`governorateName` (and the optional sibling names) are
  /// required here because `PersonsTable`'s name columns are non-null but
  /// Groups/Classification aren't Tier-1-cached yet (rows 7-8) — there's no
  /// local source to resolve them from otherwise. Callers pass whatever
  /// display name they already have (e.g. from an already-loaded picker
  /// list).
  Future<Either<Failure, Person>> createPerson({
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
    String? facebookUrl,
  });

  Future<Either<Failure, Person>> updatePerson({
    required int id,
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
    String? facebookUrl,
  });

  /// Same as [createPerson] but also asks `SyncService` to replay this
  /// specific outbox row immediately and awaits the outcome (awaited here,
  /// in the repository/data layer — never by a cubit, per CLAUDE.md's
  /// DI-scopes table). `Right(Person)` means the person now has a real
  /// server id. `Left(failure)` means the immediate sync attempt failed
  /// right now (offline/server error) — the queued row is NOT rolled back
  /// and will still sync in the background later, but this call reports
  /// failure so callers needing a synchronously-resolved real id (photo/
  /// relationship uploads) can fail cleanly instead of silently proceeding
  /// against a temp id.
  Future<Either<Failure, Person>> createPersonAndSync({
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
    String? facebookUrl,
  });

  /// Same as [updatePersonAndSync]'s sibling above, with one difference:
  /// `id` here always refers to an already-real, pre-existing person, so a
  /// `NetworkFailure` (device offline right now) is treated as an accepted
  /// Tier 2 success — `Right(Person)` with the locally-queued value — not a
  /// failure, since there is no temp-id risk to guard against on an update.
  /// Any other failure (validation, server error) still propagates as
  /// `Left(failure)`.
  Future<Either<Failure, Person>> updatePersonAndSync({
    required int id,
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
    String? facebookUrl,
  });

  Future<Either<Failure, PersonOccasionHistoryEntry>> addOccasionHistory({
    required int personId,
    required bool invitedMe,
    InviteMethod? inviteMethod,
    String? occasionName,
    DateTime? occasionDate,
    String? notes,
  });
}

import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';

import '../entities/bulk_add_guests_result.dart';
import '../entities/event_guest.dart';
import '../entities/event_guest_progress_summary.dart';
import '../entities/event_guest_status.dart';

abstract class EventGuestRepository {
  Future<Either<Failure, PaginatedResult<EventGuest>>> getEventGuests(
    int eventId, {
    int? groupId,
    EventGuestStatus? status,
    required int pageIndex,
    required int pageSize,
  });

  /// Tier 1 read path for `EventGuestsListCubit`/`AddGuestsListCubit`
  /// (local-first, CLAUDE.md rule 7) — reads local drift only, never touches
  /// the network. `limit` grows as `loadMore()` is called (design doc §3).
  Stream<List<EventGuest>> watchEventGuests({
    required int eventId,
    int? groupId,
    EventGuestStatus? status,
    required int limit,
  });

  /// One-shot exact count for the same filter set, local-only — backs
  /// `hasNextPage` without a `length == limit` heuristic.
  Future<int> countEventGuests({required int eventId, int? groupId, EventGuestStatus? status});

  /// Tier 3 background pull (design doc §6) — **permanent**
  /// full-refetch-as-delta, not an interim stage (row 9 cross-cutting
  /// decision: EventGuest is hard-delete-only). Called by
  /// `EventGuestCollectionPuller` from `SyncService`'s background pull
  /// cadence, never awaited from a cubit or screen.
  Future<Either<Failure, Unit>> refreshEventGuests();

  /// Server-computed, stays network-only forever (design doc §8) — never
  /// cached, never routed through local drift.
  Future<Either<Failure, EventGuestProgressSummary>> getProgress(int eventId);

  /// Server-computed, stays network-only forever (design doc §8).
  Future<Either<Failure, PaginatedResult<Person>>> getReciprocitySuggestions(
    int eventId, {
    int? groupId,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, BulkAddGuestsResult>> addPersonsToEvent({
    required int eventId,
    required List<int> personIds,
  });

  Future<Either<Failure, BulkAddGuestsResult>> addGroupToEvent({
    required int eventId,
    required int groupId,
  });

  Future<Either<Failure, BulkAddGuestsResult>> addSubGroupToEvent({
    required int eventId,
    required int subGroupId,
  });

  Future<Either<Failure, BulkAddGuestsResult>> addGovernorateToEvent({
    required int eventId,
    required int governorateId,
  });

  Future<Either<Failure, BulkAddGuestsResult>> addCityToEvent({
    required int eventId,
    required int cityId,
  });

  Future<Either<Failure, BulkAddGuestsResult>> addNeighborhoodToEvent({
    required int eventId,
    required int neighborhoodId,
  });

  Future<Either<Failure, EventGuest>> markInvited(
    int eventId,
    int guestId, {
    required InviteMethod inviteMethod,
  });

  Future<Either<Failure, EventGuest>> markSkipped(int eventId, int guestId);

  Future<Either<Failure, EventGuest>> revertGuest(int eventId, int guestId);

  Future<Either<Failure, Unit>> removeGuest(int eventId, int guestId);
}

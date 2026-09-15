import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/add_persons_to_event_request.dart';
import '../models/bulk_add_guests_result_response.dart';
import '../models/event_guest_progress_summary_response.dart';
import '../models/event_guest_response.dart';
import '../models/mark_guest_invited_request.dart';
import '../models/reciprocity_person_response.dart';
import '../../domain/entities/event_guest_status.dart';

/// Contract for `EventGuestRepositoryImpl`'s remote dependency, mirrors
/// `BaseEventDataSource`. EventGuest's first abstract data-source seam — the
/// concrete `EventGuestRemoteDataSourceImpl` was previously injected
/// directly. `getProgress`/`getReciprocitySuggestions` stay network-only
/// forever (design doc §8) — never cached, never routed through local drift.
abstract class BaseEventGuestDataSource {
  Future<Either<Failure, PaginatedResponse<EventGuestResponse>>> getEventGuests(
    int eventId, {
    int? groupId,
    EventGuestStatus? status,
    required int pageIndex,
    required int pageSize,
  });

  /// Flat "all mine" pull (row 9.8) — event-agnostic, feeds Tier 1's bulk
  /// local population and (row 9.10) the permanent full-refetch pull.
  Future<Either<Failure, List<EventGuestResponse>>> getAllMineEventGuests();

  Future<Either<Failure, EventGuestProgressSummaryResponse>> getProgress(int eventId);

  Future<Either<Failure, PaginatedResponse<ReciprocityPersonResponse>>> getReciprocitySuggestions(
    int eventId, {
    int? groupId,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, BulkAddGuestsResultResponse>> addPersonsToEvent(
    int eventId,
    AddPersonsToEventRequest request,
  );

  Future<Either<Failure, BulkAddGuestsResultResponse>> addGroupToEvent(int eventId, int groupId);

  Future<Either<Failure, BulkAddGuestsResultResponse>> addSubGroupToEvent(int eventId, int subGroupId);

  Future<Either<Failure, BulkAddGuestsResultResponse>> addGovernorateToEvent(int eventId, int governorateId);

  Future<Either<Failure, BulkAddGuestsResultResponse>> addCityToEvent(int eventId, int cityId);

  Future<Either<Failure, BulkAddGuestsResultResponse>> addNeighborhoodToEvent(int eventId, int neighborhoodId);

  Future<Either<Failure, EventGuestResponse>> markInvited(
    int eventId,
    int guestId,
    MarkGuestInvitedRequest request,
  );

  Future<Either<Failure, EventGuestResponse>> markSkipped(int eventId, int guestId);

  Future<Either<Failure, EventGuestResponse>> revertGuest(int eventId, int guestId);

  Future<Either<Failure, Unit>> removeGuest(int eventId, int guestId);
}

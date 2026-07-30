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

  Future<Either<Failure, EventGuestProgressSummary>> getProgress(int eventId);

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

  Future<Either<Failure, EventGuest>> markInvited(
    int eventId,
    int guestId, {
    required InviteMethod inviteMethod,
  });

  Future<Either<Failure, EventGuest>> markSkipped(int eventId, int guestId);

  Future<Either<Failure, EventGuest>> revertGuest(int eventId, int guestId);

  Future<Either<Failure, Unit>> removeGuest(int eventId, int guestId);
}

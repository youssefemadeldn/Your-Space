import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/entities/bulk_add_guests_result.dart';
import '../../domain/entities/event_guest.dart';
import '../../domain/entities/event_guest_progress_summary.dart';
import '../../domain/entities/event_guest_status.dart';
import '../../domain/repositories/base_event_guest_repository.dart';
import '../datasources/event_guest_remote_data_source_impl.dart';
import '../models/add_persons_to_event_request.dart';
import '../models/mark_guest_invited_request.dart';

@LazySingleton(as: EventGuestRepository)
class EventGuestRepositoryImpl implements EventGuestRepository {
  final EventGuestRemoteDataSourceImpl _remote;

  EventGuestRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResult<EventGuest>>> getEventGuests(
    int eventId, {
    int? groupId,
    EventGuestStatus? status,
    required int pageIndex,
    required int pageSize,
  }) async {
    final result = await _remote.getEventGuests(
      eventId,
      groupId: groupId,
      status: status,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
    return result.fold(Left.new, (response) => Right(response.toResult((r) => r.toEntity(eventId))));
  }

  @override
  Future<Either<Failure, EventGuestProgressSummary>> getProgress(int eventId) async {
    final result = await _remote.getProgress(eventId);
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, PaginatedResult<Person>>> getReciprocitySuggestions(
    int eventId, {
    int? groupId,
    required int pageIndex,
    required int pageSize,
  }) async {
    final result = await _remote.getReciprocitySuggestions(
      eventId,
      groupId: groupId,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
    return result.fold(Left.new, (response) => Right(response.toResult((r) => r.toEntity())));
  }

  @override
  Future<Either<Failure, BulkAddGuestsResult>> addPersonsToEvent({
    required int eventId,
    required List<int> personIds,
  }) async {
    final result =
        await _remote.addPersonsToEvent(eventId, AddPersonsToEventRequest(personIds: personIds));
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, BulkAddGuestsResult>> addGroupToEvent({
    required int eventId,
    required int groupId,
  }) async {
    final result = await _remote.addGroupToEvent(eventId, groupId);
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, EventGuest>> markInvited(
    int eventId,
    int guestId, {
    required InviteMethod inviteMethod,
  }) async {
    final result =
        await _remote.markInvited(eventId, guestId, MarkGuestInvitedRequest(inviteMethod: inviteMethod));
    return result.fold(Left.new, (response) => Right(response.toEntity(eventId)));
  }

  @override
  Future<Either<Failure, EventGuest>> markSkipped(int eventId, int guestId) async {
    final result = await _remote.markSkipped(eventId, guestId);
    return result.fold(Left.new, (response) => Right(response.toEntity(eventId)));
  }

  @override
  Future<Either<Failure, EventGuest>> revertGuest(int eventId, int guestId) async {
    final result = await _remote.revertGuest(eventId, guestId);
    return result.fold(Left.new, (response) => Right(response.toEntity(eventId)));
  }

  @override
  Future<Either<Failure, Unit>> removeGuest(int eventId, int guestId) =>
      _remote.removeGuest(eventId, guestId);
}

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/constants/api_constants.dart';
import 'package:your_space_mobile/core/network/api_envelope.dart';
import 'package:your_space_mobile/core/network/api_manager.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';
import '../models/add_persons_to_event_request.dart';
import '../models/bulk_add_guests_result_response.dart';
import '../models/event_guest_progress_summary_response.dart';
import '../models/event_guest_response.dart';
import '../models/mark_guest_invited_request.dart';
import '../models/reciprocity_person_response.dart';

@lazySingleton
class EventGuestRemoteDataSourceImpl {
  final ApiManager _api;

  EventGuestRemoteDataSourceImpl(this._api);

  String _guestsPath(int eventId) => '${ApiConstants.events}/$eventId/guests';

  Future<Either<Failure, PaginatedResponse<EventGuestResponse>>> getEventGuests(
    int eventId, {
    int? groupId,
    EventGuestStatus? status,
    required int pageIndex,
    required int pageSize,
  }) =>
      _api.get<PaginatedResponse<EventGuestResponse>>(
        path: _guestsPath(eventId),
        queryParameters: {
          'groupId': ?groupId,
          if (status != null) 'status': status.toWire(),
          'pageIndex': pageIndex,
          'pageSize': pageSize,
        },
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PaginatedResponse.fromJson(
            inner as Map<String, dynamic>,
            (item) => EventGuestResponse.fromJson(item as Map<String, dynamic>),
          ),
        ),
      );

  Future<Either<Failure, EventGuestProgressSummaryResponse>> getProgress(int eventId) =>
      _api.get<EventGuestProgressSummaryResponse>(
        path: '${_guestsPath(eventId)}/progress',
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => EventGuestProgressSummaryResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, PaginatedResponse<ReciprocityPersonResponse>>> getReciprocitySuggestions(
    int eventId, {
    int? groupId,
    required int pageIndex,
    required int pageSize,
  }) =>
      _api.get<PaginatedResponse<ReciprocityPersonResponse>>(
        path: '${_guestsPath(eventId)}/reciprocity-suggestions',
        queryParameters: {
          'groupId': ?groupId,
          'pageIndex': pageIndex,
          'pageSize': pageSize,
        },
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PaginatedResponse.fromJson(
            inner as Map<String, dynamic>,
            (item) => ReciprocityPersonResponse.fromJson(item as Map<String, dynamic>),
          ),
        ),
      );

  Future<Either<Failure, BulkAddGuestsResultResponse>> addPersonsToEvent(
    int eventId,
    AddPersonsToEventRequest request,
  ) =>
      _api.post<BulkAddGuestsResultResponse>(
        path: _guestsPath(eventId),
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => BulkAddGuestsResultResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, BulkAddGuestsResultResponse>> addGroupToEvent(int eventId, int groupId) =>
      _api.post<BulkAddGuestsResultResponse>(
        path: '${_guestsPath(eventId)}/by-group/$groupId',
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => BulkAddGuestsResultResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, BulkAddGuestsResultResponse>> addSubGroupToEvent(int eventId, int subGroupId) =>
      _api.post<BulkAddGuestsResultResponse>(
        path: '${_guestsPath(eventId)}/by-subgroup/$subGroupId',
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => BulkAddGuestsResultResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, BulkAddGuestsResultResponse>> addGovernorateToEvent(int eventId, int governorateId) =>
      _api.post<BulkAddGuestsResultResponse>(
        path: '${_guestsPath(eventId)}/by-governorate/$governorateId',
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => BulkAddGuestsResultResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, BulkAddGuestsResultResponse>> addCityToEvent(int eventId, int cityId) =>
      _api.post<BulkAddGuestsResultResponse>(
        path: '${_guestsPath(eventId)}/by-city/$cityId',
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => BulkAddGuestsResultResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, BulkAddGuestsResultResponse>> addNeighborhoodToEvent(int eventId, int neighborhoodId) =>
      _api.post<BulkAddGuestsResultResponse>(
        path: '${_guestsPath(eventId)}/by-neighborhood/$neighborhoodId',
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => BulkAddGuestsResultResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, EventGuestResponse>> markInvited(
    int eventId,
    int guestId,
    MarkGuestInvitedRequest request,
  ) =>
      _api.post<EventGuestResponse>(
        path: '${_guestsPath(eventId)}/$guestId/invite',
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => EventGuestResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, EventGuestResponse>> markSkipped(int eventId, int guestId) =>
      _api.post<EventGuestResponse>(
        path: '${_guestsPath(eventId)}/$guestId/skip',
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => EventGuestResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, EventGuestResponse>> revertGuest(int eventId, int guestId) =>
      _api.post<EventGuestResponse>(
        path: '${_guestsPath(eventId)}/$guestId/revert',
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => EventGuestResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, Unit>> removeGuest(int eventId, int guestId) => _api.delete<Unit>(
        path: '${_guestsPath(eventId)}/$guestId',
        fromJson: (_) => unit,
      );
}

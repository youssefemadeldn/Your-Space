import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/constants/api_constants.dart';
import 'package:your_space_mobile/core/network/api_envelope.dart';
import 'package:your_space_mobile/core/network/api_manager.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/create_event_request.dart';
import '../models/event_response.dart';
import '../models/update_event_request.dart';

@lazySingleton
class EventRemoteDataSourceImpl {
  final ApiManager _api;

  EventRemoteDataSourceImpl(this._api);

  Future<Either<Failure, PaginatedResponse<EventResponse>>> getEvents({
    String? search,
    required int pageIndex,
    required int pageSize,
  }) =>
      _api.get<PaginatedResponse<EventResponse>>(
        path: ApiConstants.events,
        queryParameters: {
          'search': ?search,
          'pageIndex': pageIndex,
          'pageSize': pageSize,
        },
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PaginatedResponse.fromJson(
            inner as Map<String, dynamic>,
            (item) => EventResponse.fromJson(item as Map<String, dynamic>),
          ),
        ),
      );

  Future<Either<Failure, EventResponse>> getEventById(int id) => _api.get<EventResponse>(
        path: '${ApiConstants.events}/$id',
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => EventResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, EventResponse>> createEvent(CreateEventRequest request) =>
      _api.post<EventResponse>(
        path: ApiConstants.events,
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => EventResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, EventResponse>> updateEvent(UpdateEventRequest request) =>
      _api.put<EventResponse>(
        path: ApiConstants.events,
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => EventResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );
}

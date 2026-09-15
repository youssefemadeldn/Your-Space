import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/create_event_request.dart';
import '../models/event_changes_response.dart';
import '../models/event_response.dart';
import '../models/update_event_request.dart';

/// Contract for `EventRepositoryImpl`'s remote dependency, mirrors
/// `BaseGroupDataSource`/`BaseCityDataSource`. Event's first abstract
/// data-source seam — the concrete `EventRemoteDataSourceImpl` was
/// previously injected directly. `EventLocalDataSourceImpl` does not
/// implement this contract; it's a separate, concrete local surface.
abstract class BaseEventDataSource {
  /// Already flat/owner-scoped (Event has no nested-only history, unlike
  /// Classification) — reused as-is for both the paginated screen fallback
  /// and Tier 3's interim full-refetch loop (row 9.4).
  Future<Either<Failure, PaginatedResponse<EventResponse>>> getEvents({
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, EventResponse>> getEventById(int id);

  Future<Either<Failure, EventResponse>> createEvent(CreateEventRequest request);

  Future<Either<Failure, EventResponse>> updateEvent(UpdateEventRequest request);

  /// Tier 3 real delta pull (design doc §6, row 9.6): [since] is the last
  /// cursor seen (0 on first sync); the response's `hasMore` tells the
  /// caller whether to keep paging with the returned `cursor` as the next
  /// `since`.
  Future<Either<Failure, EventChangesResponse>> getEventChanges({
    required int since,
    required int pageSize,
  });
}

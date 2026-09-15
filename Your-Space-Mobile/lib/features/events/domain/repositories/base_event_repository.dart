import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';

import '../entities/event.dart';

abstract class EventRepository {
  Future<Either<Failure, PaginatedResult<Event>>> getEvents({
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, Event>> getEventById(int id);

  /// Tier 1 read path for `EventsListCubit` (local-first, CLAUDE.md rule 7)
  /// — reads local drift only, never touches the network. `limit` grows as
  /// `loadMore()` is called; the caller resubscribes rather than tracking an
  /// offset (design doc §3).
  Stream<List<Event>> watchEvents({String? search, required int limit});

  /// One-shot exact count for the same filter set, local-only — backs
  /// `hasNextPage` without a `length == limit` heuristic.
  Future<int> countEvents({String? search});

  /// Tier 3 background pull (design doc §6) — real cursor-based delta from
  /// the start (row 9.5/9.6 landed together in this sprint, so no throwaway
  /// interim full-refetch stage was built). Called by `EventCollectionPuller`
  /// from `SyncService`'s background pull cadence, never awaited from a
  /// cubit or screen.
  Future<Either<Failure, Unit>> refreshEvents();

  Future<Either<Failure, Event>> createEvent({
    required String name,
    String? nameAr,
    DateTime? eventDate,
    String? notes,
  });

  Future<Either<Failure, Event>> updateEvent({
    required int id,
    required String name,
    String? nameAr,
    DateTime? eventDate,
    String? notes,
  });
}

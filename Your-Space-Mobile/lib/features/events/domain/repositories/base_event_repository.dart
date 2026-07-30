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

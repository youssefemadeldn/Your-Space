import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/base_event_repository.dart';
import '../datasources/event_remote_data_source_impl.dart';
import '../models/create_event_request.dart';
import '../models/update_event_request.dart';

@LazySingleton(as: EventRepository)
class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSourceImpl _remote;

  EventRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResult<Event>>> getEvents({
    String? search,
    required int pageIndex,
    required int pageSize,
  }) async {
    final result = await _remote.getEvents(search: search, pageIndex: pageIndex, pageSize: pageSize);
    return result.fold(Left.new, (response) => Right(response.toResult((r) => r.toEntity())));
  }

  @override
  Future<Either<Failure, Event>> getEventById(int id) async {
    final result = await _remote.getEventById(id);
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, Event>> createEvent({
    required String name,
    String? nameAr,
    DateTime? eventDate,
    String? notes,
  }) async {
    final result = await _remote.createEvent(
      CreateEventRequest(name: name, nameAr: nameAr, eventDate: eventDate, notes: notes),
    );
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, Event>> updateEvent({
    required int id,
    required String name,
    String? nameAr,
    DateTime? eventDate,
    String? notes,
  }) async {
    final result = await _remote.updateEvent(
      UpdateEventRequest(id: id, name: name, nameAr: nameAr, eventDate: eventDate, notes: notes),
    );
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }
}

import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/base_event_repository.dart';
import '../datasources/base_event_data_source.dart';
import '../datasources/event_local_data_source_impl.dart';
import '../models/create_event_request.dart';
import '../models/update_event_request.dart';

@LazySingleton(as: EventRepository)
class EventRepositoryImpl implements EventRepository {
  final BaseEventDataSource _remote;
  final EventLocalDataSourceImpl _local;

  EventRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
  );

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
  Stream<List<Event>> watchEvents({String? search, required int limit}) =>
      _local.watchEvents(search: search, limit: limit);

  @override
  Future<int> countEvents({String? search}) => _local.countEvents(search: search);

  @override
  Future<Either<Failure, Unit>> refreshEvents() async {
    const pageSize = 200;
    // Defensive cap against a pathological `hasMore` loop.
    const maxPages = 50;
    var cursor = await _local.getEventsSyncCursor();
    for (var page = 0; page < maxPages; page++) {
      final result = await _remote.getEventChanges(since: cursor, pageSize: pageSize);
      if (result.isLeft()) {
        return result.fold(Left.new, (_) => throw StateError('unreachable'));
      }
      final changes = result.getOrElse(() => throw StateError('unreachable'));
      await _local.applyEventChanges(
        upserts: changes.upserts.map((r) => r.toEntity()).toList(),
        tombstoneIds: changes.tombstoneIds,
      );
      await _local.saveEventsSyncCursor(changes.cursor);
      cursor = changes.cursor;
      if (!changes.hasMore) break;
    }
    return const Right(unit);
  }

  int _newTempEventId() => -DateTime.now().microsecondsSinceEpoch;

  @override
  Future<Either<Failure, Event>> createEvent({
    required String name,
    String? nameAr,
    DateTime? eventDate,
    String? notes,
  }) async {
    final event = Event(id: _newTempEventId(), name: name, nameAr: nameAr, eventDate: eventDate, notes: notes);
    final payloadJson = jsonEncode(
      CreateEventRequest(name: name, nameAr: nameAr, eventDate: eventDate, notes: notes).toJson(),
    );
    await _local.queueEventMutation(event: event, operation: 'create', payloadJson: payloadJson);
    return Right(event);
  }

  @override
  Future<Either<Failure, Event>> updateEvent({
    required int id,
    required String name,
    String? nameAr,
    DateTime? eventDate,
    String? notes,
  }) async {
    final event = Event(id: id, name: name, nameAr: nameAr, eventDate: eventDate, notes: notes);
    final payloadJson = jsonEncode(
      UpdateEventRequest(id: id, name: name, nameAr: nameAr, eventDate: eventDate, notes: notes).toJson(),
    );
    await _local.queueEventMutation(event: event, operation: 'update', payloadJson: payloadJson);
    return Right(event);
  }
}

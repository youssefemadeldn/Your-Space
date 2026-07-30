import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/events/data/datasources/event_remote_data_source_impl.dart';
import 'package:your_space_mobile/features/events/data/models/create_event_request.dart';
import 'package:your_space_mobile/features/events/data/models/event_response.dart';
import 'package:your_space_mobile/features/events/data/models/update_event_request.dart';
import 'package:your_space_mobile/features/events/data/repositories/event_repository_impl.dart';
import 'package:your_space_mobile/features/events/domain/entities/event.dart';

class MockEventRemoteDataSourceImpl extends Mock implements EventRemoteDataSourceImpl {}

void main() {
  late MockEventRemoteDataSourceImpl remote;
  late EventRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const CreateEventRequest(name: ''));
    registerFallbackValue(const UpdateEventRequest(id: 0, name: ''));
  });

  setUp(() {
    remote = MockEventRemoteDataSourceImpl();
    repository = EventRepositoryImpl(remote);
  });

  test('getEventById maps the response to an entity', () async {
    when(() => remote.getEventById(1)).thenAnswer(
      (_) async => const Right(EventResponse(id: 1, name: "Sara's Birthday", totalGuestCount: 5)),
    );

    final result = await repository.getEventById(1);

    expect(result, const Right(Event(id: 1, name: "Sara's Birthday", totalGuestCount: 5)));
  });

  test('getEventById propagates a failure unchanged', () async {
    const failure = ServerFailure(statusCode: 404, message: 'Not found', errorCode: 'Event.NotFound');
    when(() => remote.getEventById(999)).thenAnswer((_) async => const Left(failure));

    final result = await repository.getEventById(999);

    expect(result, const Left(failure));
  });

  test('createEvent maps the response to an entity', () async {
    when(() => remote.createEvent(any()))
        .thenAnswer((_) async => const Right(EventResponse(id: 3, name: 'New Event', totalGuestCount: 0)));

    final result = await repository.createEvent(name: 'New Event');

    expect(result, const Right(Event(id: 3, name: 'New Event')));
  });
}

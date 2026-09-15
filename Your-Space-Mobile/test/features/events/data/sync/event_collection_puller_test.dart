import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/events/data/sync/event_collection_puller.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository repository;
  late EventCollectionPuller puller;

  setUp(() {
    repository = MockEventRepository();
    GetIt.instance.registerSingleton<EventRepository>(repository);
    puller = EventCollectionPuller();
  });

  tearDown(() => GetIt.instance.reset());

  test('collection is events', () {
    expect(puller.collection, 'events');
  });

  test('pull delegates straight to EventRepository.refreshEvents', () async {
    when(() => repository.refreshEvents()).thenAnswer((_) async => const Right(unit));

    final result = await puller.pull();

    expect(result, const Right(unit));
    verify(() => repository.refreshEvents()).called(1);
  });

  test('pull propagates a failure from refreshEvents unchanged', () async {
    const failure = NetworkFailure();
    when(() => repository.refreshEvents()).thenAnswer((_) async => const Left(failure));

    final result = await puller.pull();

    expect(result, const Left(failure));
  });
}

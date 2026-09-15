import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/events/data/sync/event_guest_collection_puller.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';

class MockEventGuestRepository extends Mock implements EventGuestRepository {}

void main() {
  late MockEventGuestRepository repository;
  late EventGuestCollectionPuller puller;

  setUp(() {
    repository = MockEventGuestRepository();
    GetIt.instance.registerSingleton<EventGuestRepository>(repository);
    puller = EventGuestCollectionPuller();
  });

  tearDown(() => GetIt.instance.reset());

  test('collection is eventGuests', () {
    expect(puller.collection, 'eventGuests');
  });

  test('pull delegates straight to EventGuestRepository.refreshEventGuests', () async {
    when(() => repository.refreshEventGuests()).thenAnswer((_) async => const Right(unit));

    final result = await puller.pull();

    expect(result, const Right(unit));
    verify(() => repository.refreshEventGuests()).called(1);
  });

  test('pull propagates a failure from refreshEventGuests unchanged', () async {
    const failure = NetworkFailure();
    when(() => repository.refreshEventGuests()).thenAnswer((_) async => const Left(failure));

    final result = await puller.pull();

    expect(result, const Left(failure));
  });
}

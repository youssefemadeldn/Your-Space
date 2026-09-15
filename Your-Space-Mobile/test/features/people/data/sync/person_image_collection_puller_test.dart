import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/people/data/sync/person_image_collection_puller.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_image_repository.dart';

class MockPersonImageRepository extends Mock implements PersonImageRepository {}

void main() {
  late MockPersonImageRepository repository;
  late PersonImageCollectionPuller puller;

  setUp(() {
    repository = MockPersonImageRepository();
    puller = PersonImageCollectionPuller(repository);
  });

  test('collection is personImages', () {
    expect(puller.collection, 'personImages');
  });

  test('pull delegates straight to PersonImageRepository.refreshImages', () async {
    when(() => repository.refreshImages()).thenAnswer((_) async => const Right(unit));

    final result = await puller.pull();

    expect(result, const Right(unit));
    verify(() => repository.refreshImages()).called(1);
  });

  test('pull propagates a failure from refreshImages unchanged', () async {
    const failure = NetworkFailure();
    when(() => repository.refreshImages()).thenAnswer((_) async => const Left(failure));

    final result = await puller.pull();

    expect(result, const Left(failure));
  });
}

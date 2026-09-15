import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/data/sync/neighborhood_collection_puller.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart';

class MockNeighborhoodRepository extends Mock implements NeighborhoodRepository {}

void main() {
  late MockNeighborhoodRepository repository;
  late NeighborhoodCollectionPuller puller;

  setUp(() {
    repository = MockNeighborhoodRepository();
    GetIt.instance.registerSingleton<NeighborhoodRepository>(repository);
    puller = NeighborhoodCollectionPuller();
  });

  tearDown(() => GetIt.instance.reset());

  test('collection is neighborhoods', () {
    expect(puller.collection, 'neighborhoods');
  });

  test('pull delegates straight to NeighborhoodRepository.refreshNeighborhoods', () async {
    when(() => repository.refreshNeighborhoods()).thenAnswer((_) async => const Right(unit));

    final result = await puller.pull();

    expect(result, const Right(unit));
    verify(() => repository.refreshNeighborhoods()).called(1);
  });

  test('pull propagates a failure from refreshNeighborhoods unchanged', () async {
    const failure = NetworkFailure();
    when(() => repository.refreshNeighborhoods()).thenAnswer((_) async => const Left(failure));

    final result = await puller.pull();

    expect(result, const Left(failure));
  });
}

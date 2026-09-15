import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/data/sync/city_collection_puller.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart';

class MockCityRepository extends Mock implements CityRepository {}

void main() {
  late MockCityRepository repository;
  late CityCollectionPuller puller;

  setUp(() {
    repository = MockCityRepository();
    GetIt.instance.registerSingleton<CityRepository>(repository);
    puller = CityCollectionPuller();
  });

  tearDown(() => GetIt.instance.reset());

  test('collection is cities', () {
    expect(puller.collection, 'cities');
  });

  test('pull delegates straight to CityRepository.refreshCities', () async {
    when(() => repository.refreshCities()).thenAnswer((_) async => const Right(unit));

    final result = await puller.pull();

    expect(result, const Right(unit));
    verify(() => repository.refreshCities()).called(1);
  });

  test('pull propagates a failure from refreshCities unchanged', () async {
    const failure = NetworkFailure();
    when(() => repository.refreshCities()).thenAnswer((_) async => const Left(failure));

    final result = await puller.pull();

    expect(result, const Left(failure));
  });
}

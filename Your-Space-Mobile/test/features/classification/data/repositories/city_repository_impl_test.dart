import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/features/classification/data/datasources/base_city_data_source.dart';
import 'package:your_space_mobile/features/classification/data/datasources/city_local_data_source_impl.dart';
import 'package:your_space_mobile/features/classification/data/models/city_response.dart';
import 'package:your_space_mobile/features/classification/data/models/create_city_request.dart';
import 'package:your_space_mobile/features/classification/data/models/update_city_request.dart';
import 'package:your_space_mobile/features/classification/data/repositories/city_repository_impl.dart';

class MockBaseCityDataSource extends Mock implements BaseCityDataSource {}

class MockCityLocalDataSourceImpl extends Mock implements CityLocalDataSourceImpl {}

void main() {
  late MockBaseCityDataSource remote;
  late MockCityLocalDataSourceImpl local;
  late CityRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const City(id: 0, governorateId: 0, name: ''));
    registerFallbackValue(const CreateCityRequest(name: ''));
    registerFallbackValue(const UpdateCityRequest(name: ''));
  });

  setUp(() {
    remote = MockBaseCityDataSource();
    local = MockCityLocalDataSourceImpl();
    repository = CityRepositoryImpl(remote, local);
    when(() => local.saveCity(any())).thenAnswer((_) async {});
    when(() => local.deleteCityLocal(any())).thenAnswer((_) async {});
  });

  test('getCities maps a paginated response to a PaginatedResult of entities', () async {
    when(() => remote.getCities(governorateId: 7, search: any(named: 'search'), pageIndex: 1, pageSize: 20))
        .thenAnswer(
      (_) async => const Right(PaginatedResponse(
        items: [
          CityResponse(id: 1, governorateId: 7, name: 'Maadi'),
          CityResponse(id: 2, governorateId: 7, name: 'Nasr City'),
        ],
        pageIndex: 1,
        totalPages: 1,
        totalItems: 2,
      )),
    );

    final result = await repository.getCities(governorateId: 7, pageIndex: 1, pageSize: 20);

    expect(result.isRight(), isTrue);
    final page = result.getOrElse(() => throw StateError('expected Right'));
    expect(page.items.map((c) => c.name), ['Maadi', 'Nasr City']);
    expect(page.totalItems, 2);
  });

  test('getCities propagates a failure unchanged', () async {
    const failure = NetworkFailure();
    when(() => remote.getCities(governorateId: 7, search: any(named: 'search'), pageIndex: 1, pageSize: 20))
        .thenAnswer((_) async => const Left(failure));

    final result = await repository.getCities(governorateId: 7, pageIndex: 1, pageSize: 20);

    expect(result, const Left(failure));
  });

  test('watchCities delegates straight to the local data source', () {
    when(() => local.watchCities(governorateId: 7, search: 'ma', limit: 20)).thenAnswer(
      (_) => Stream.value(const [City(id: 1, governorateId: 7, name: 'Maadi')]),
    );

    final stream = repository.watchCities(governorateId: 7, search: 'ma', limit: 20);

    expect(stream, emits(const [City(id: 1, governorateId: 7, name: 'Maadi')]));
  });

  test('countCities delegates straight to the local data source', () async {
    when(() => local.countCities(governorateId: 7, search: null)).thenAnswer((_) async => 5);

    final count = await repository.countCities(governorateId: 7);

    expect(count, 5);
  });

  test('createCity maps the response to an entity and saves it locally', () async {
    when(() => remote.createCity(7, any()))
        .thenAnswer((_) async => const Right(CityResponse(id: 5, governorateId: 7, name: 'Book club')));

    final result = await repository.createCity(governorateId: 7, name: 'Book club');

    expect(result, const Right(City(id: 5, governorateId: 7, name: 'Book club')));
    verify(() => local.saveCity(const City(id: 5, governorateId: 7, name: 'Book club'))).called(1);
  });

  test('createCity propagates a failure without touching local storage', () async {
    const failure = NetworkFailure();
    when(() => remote.createCity(7, any())).thenAnswer((_) async => const Left(failure));

    final result = await repository.createCity(governorateId: 7, name: 'Book club');

    expect(result, const Left(failure));
    verifyNever(() => local.saveCity(any()));
  });

  test('updateCity maps the response to an entity and saves it locally', () async {
    when(() => remote.updateCity(7, 1, any()))
        .thenAnswer((_) async => const Right(CityResponse(id: 1, governorateId: 7, name: 'Maadi (Updated)')));

    final result = await repository.updateCity(governorateId: 7, id: 1, name: 'Maadi (Updated)');

    expect(result, const Right(City(id: 1, governorateId: 7, name: 'Maadi (Updated)')));
    verify(() => local.saveCity(const City(id: 1, governorateId: 7, name: 'Maadi (Updated)'))).called(1);
  });

  test('deleteCity removes the row locally after a successful remote delete', () async {
    when(() => remote.deleteCity(7, 1)).thenAnswer((_) async => const Right(unit));

    final result = await repository.deleteCity(governorateId: 7, id: 1);

    expect(result, const Right(unit));
    verify(() => local.deleteCityLocal(1)).called(1);
  });

  test('deleteCity propagates a failure without touching local storage', () async {
    const failure = NetworkFailure();
    when(() => remote.deleteCity(7, 1)).thenAnswer((_) async => const Left(failure));

    final result = await repository.deleteCity(governorateId: 7, id: 1);

    expect(result, const Left(failure));
    verifyNever(() => local.deleteCityLocal(any()));
  });
}

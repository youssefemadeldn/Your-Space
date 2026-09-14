import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/city_list_cubit/city_list_cubit.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/city_list_cubit/city_list_state.dart';

class MockCityRepository extends Mock implements CityRepository {}

void main() {
  late MockCityRepository repository;
  late DataRefreshBus dataRefreshBus;
  late CityListCubit cubit;

  const city1 = City(id: 1, governorateId: 7, name: 'Maadi');
  const city2 = City(id: 2, governorateId: 7, name: 'Nasr City');

  PaginatedResult<City> page(List<City> items) =>
      PaginatedResult(items: items, pageIndex: 1, totalPages: 1, totalItems: items.length);

  /// Stubs a `watchCities`/`countCities` pair for a given search/limit.
  void stubCities({
    int governorateId = 7,
    String? search,
    required int limit,
    required List<City> cities,
    required int total,
  }) {
    when(() => repository.watchCities(governorateId: governorateId, search: search, limit: limit))
        .thenAnswer((_) => Stream.value(cities));
    when(() => repository.countCities(governorateId: governorateId, search: search)).thenAnswer((_) async => total);
  }

  /// The one-shot `getCities` call `CityListCubit` uses purely to read
  /// `neighborhoodCount` (design doc §8) — defaults to an empty page
  /// (counts default to 0) unless a test stubs otherwise.
  void stubCounts({int governorateId = 7, List<City> withCounts = const []}) {
    when(() => repository.getCities(governorateId: governorateId, pageIndex: 1, pageSize: 200))
        .thenAnswer((_) async => Right(page(withCounts)));
  }

  setUp(() {
    repository = MockCityRepository();
    dataRefreshBus = DataRefreshBus();
    cubit = CityListCubit(repository, dataRefreshBus);
    stubCounts();
  });

  tearDown(() {
    cubit.close();
    dataRefreshBus.dispose();
  });

  test('emits [Loading, Success] with the first window on load', () async {
    stubCities(limit: 20, cities: const [city1, city2], total: 2);

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const CityListLoading(),
        isA<CityListSuccess>()
            .having((s) => s.cities.length, 'cities.length', 2)
            .having((s) => s.hasNextPage, 'hasNextPage', false),
      ]),
    );

    await cubit.load(7);
    await expectation;
  });

  test('merges the one-shot neighborhoodCount onto each locally-cached row', () async {
    stubCities(limit: 20, cities: const [city1, city2], total: 2);
    stubCounts(withCounts: const [
      City(id: 1, governorateId: 7, name: 'Maadi', neighborhoodCount: 3),
      City(id: 2, governorateId: 7, name: 'Nasr City', neighborhoodCount: 5),
    ]);

    await cubit.load(7);

    final state = cubit.state as CityListSuccess;
    expect(state.cities.singleWhere((c) => c.id == 1).neighborhoodCount, 3);
    expect(state.cities.singleWhere((c) => c.id == 2).neighborhoodCount, 5);
  });

  test('a failed counts fetch still renders the local list, with counts left at their default', () async {
    when(() => repository.getCities(governorateId: 7, pageIndex: 1, pageSize: 200))
        .thenAnswer((_) async => const Left(NetworkFailure()));
    stubCities(limit: 20, cities: const [city1], total: 1);

    await cubit.load(7);

    final state = cubit.state as CityListSuccess;
    expect(state.cities.single.neighborhoodCount, 0);
  });

  test('emits [Loading, Error] when the local read throws', () async {
    when(() => repository.watchCities(governorateId: 7, search: null, limit: 20))
        .thenAnswer((_) => Stream.error(Exception('boom')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const CityListLoading(), isA<CityListError>()]),
    );

    await cubit.load(7);
    await expectation;
  });

  test('search debounces then resubscribes with the new filter', () async {
    stubCities(limit: 20, cities: const [city1, city2], total: 2);
    await cubit.load(7);

    stubCities(search: 'maadi', limit: 20, cities: const [city1], total: 1);

    cubit.search('maadi');
    await Future.delayed(const Duration(milliseconds: 500));

    expect(cubit.state, isA<CityListSuccess>().having((s) => s.cities, 'cities', [city1]));
  });

  test('search on an un-loaded cubit is a no-op', () async {
    cubit.search('maadi');
    await Future.delayed(const Duration(milliseconds: 500));
    expect(cubit.state, isA<CityListInitial>());
    verifyNever(() => repository.watchCities(
          governorateId: any(named: 'governorateId'),
          search: any(named: 'search'),
          limit: any(named: 'limit'),
        ));
  });

  test('loadMore grows the limit and hasNextPage reflects the exact count', () async {
    stubCities(limit: 20, cities: const [city1], total: 2);
    await cubit.load(7);
    expect((cubit.state as CityListSuccess).hasNextPage, isTrue);

    stubCities(limit: 40, cities: const [city1, city2], total: 2);

    await cubit.loadMore();

    final state = cubit.state as CityListSuccess;
    expect(state.cities, [city1, city2]);
    expect(state.limit, 40);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    stubCities(limit: 20, cities: const [city1], total: 1);
    await cubit.load(7);

    await cubit.loadMore();

    verifyNever(() => repository.watchCities(governorateId: 7, search: any(named: 'search'), limit: 40));
  });

  test('loadMore preserves the existing items/limit and resets isLoadingMore on failure', () async {
    stubCities(limit: 20, cities: const [city1], total: 2);
    await cubit.load(7);

    when(() => repository.watchCities(governorateId: 7, search: null, limit: 40))
        .thenAnswer((_) => Stream.error(Exception('boom')));

    await cubit.loadMore();

    final state = cubit.state as CityListSuccess;
    expect(state.cities, [city1]);
    expect(state.limit, 20);
    expect(state.hasNextPage, isTrue);
    expect(state.isLoadingMore, isFalse);
    expect(state.loadMoreErrorMessage, isNotNull);
    expect(state.loadMoreErrorId, 1);
  });

  test('refresh re-fetches counts and resubscribes at the current search/limit without a Loading flash', () async {
    stubCities(limit: 20, cities: const [city1], total: 1);
    await cubit.load(7);

    stubCities(limit: 20, cities: const [city1, city2], total: 2);

    final states = <dynamic>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.refresh();
    await sub.cancel();

    expect(states, isNot(contains(isA<CityListLoading>())));
    expect(cubit.state, isA<CityListSuccess>().having((s) => s.cities, 'cities', [city1, city2]));
  });

  test('a classification DataRefreshBus notification triggers a refresh', () async {
    stubCities(limit: 20, cities: const [city1], total: 1);
    await cubit.load(7);

    stubCities(limit: 20, cities: const [city1, city2], total: 2);
    dataRefreshBus.notify(DataScope.classification);
    await pumpEventQueue();

    expect(cubit.state, isA<CityListSuccess>().having((s) => s.cities, 'cities', [city1, city2]));
  });
}

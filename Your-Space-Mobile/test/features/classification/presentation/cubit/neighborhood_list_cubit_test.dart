import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/neighborhood_list_cubit/neighborhood_list_cubit.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/neighborhood_list_cubit/neighborhood_list_state.dart';

class MockNeighborhoodRepository extends Mock implements NeighborhoodRepository {}

void main() {
  late MockNeighborhoodRepository repository;
  late NeighborhoodListCubit cubit;

  const neighborhood1 = Neighborhood(id: 1, cityId: 7, name: 'Zamalek');
  const neighborhood2 = Neighborhood(id: 2, cityId: 7, name: 'Sarayat');

  PaginatedResult<Neighborhood> page(List<Neighborhood> items) =>
      PaginatedResult(items: items, pageIndex: 1, totalPages: 1, totalItems: items.length);

  /// Stubs a `watchNeighborhoods`/`countNeighborhoods` pair for a given search/limit.
  void stubNeighborhoods({
    int cityId = 7,
    String? search,
    required int limit,
    required List<Neighborhood> neighborhoods,
    required int total,
  }) {
    when(() => repository.watchNeighborhoods(cityId: cityId, search: search, limit: limit))
        .thenAnswer((_) => Stream.value(neighborhoods));
    when(() => repository.countNeighborhoods(cityId: cityId, search: search)).thenAnswer((_) async => total);
  }

  /// The one-shot `getNeighborhoods` call `NeighborhoodListCubit` uses purely
  /// to read `personCount` (design doc §8) — defaults to an empty page
  /// (counts default to 0) unless a test stubs otherwise.
  void stubCounts({int cityId = 7, List<Neighborhood> withCounts = const []}) {
    when(() => repository.getNeighborhoods(cityId: cityId, pageIndex: 1, pageSize: 200))
        .thenAnswer((_) async => Right(page(withCounts)));
  }

  setUp(() {
    repository = MockNeighborhoodRepository();
    cubit = NeighborhoodListCubit(repository);
    stubCounts();
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with the first window on load', () async {
    stubNeighborhoods(limit: 20, neighborhoods: const [neighborhood1, neighborhood2], total: 2);

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const NeighborhoodListLoading(),
        isA<NeighborhoodListSuccess>()
            .having((s) => s.neighborhoods.length, 'neighborhoods.length', 2)
            .having((s) => s.hasNextPage, 'hasNextPage', false),
      ]),
    );

    await cubit.load(7);
    await expectation;
  });

  test('merges the one-shot personCount onto each locally-cached row', () async {
    stubNeighborhoods(limit: 20, neighborhoods: const [neighborhood1, neighborhood2], total: 2);
    stubCounts(withCounts: const [
      Neighborhood(id: 1, cityId: 7, name: 'Zamalek', personCount: 3),
      Neighborhood(id: 2, cityId: 7, name: 'Sarayat', personCount: 5),
    ]);

    await cubit.load(7);

    final state = cubit.state as NeighborhoodListSuccess;
    expect(state.neighborhoods.singleWhere((n) => n.id == 1).personCount, 3);
    expect(state.neighborhoods.singleWhere((n) => n.id == 2).personCount, 5);
  });

  test('a failed counts fetch still renders the local list, with counts left at their default', () async {
    when(() => repository.getNeighborhoods(cityId: 7, pageIndex: 1, pageSize: 200))
        .thenAnswer((_) async => const Left(NetworkFailure()));
    stubNeighborhoods(limit: 20, neighborhoods: const [neighborhood1], total: 1);

    await cubit.load(7);

    final state = cubit.state as NeighborhoodListSuccess;
    expect(state.neighborhoods.single.personCount, 0);
  });

  test('emits [Loading, Error] when the local read throws', () async {
    when(() => repository.watchNeighborhoods(cityId: 7, search: null, limit: 20))
        .thenAnswer((_) => Stream.error(Exception('boom')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const NeighborhoodListLoading(), isA<NeighborhoodListError>()]),
    );

    await cubit.load(7);
    await expectation;
  });

  test('search debounces then resubscribes with the new filter', () async {
    stubNeighborhoods(limit: 20, neighborhoods: const [neighborhood1, neighborhood2], total: 2);
    await cubit.load(7);

    stubNeighborhoods(search: 'zamalek', limit: 20, neighborhoods: const [neighborhood1], total: 1);

    cubit.search('zamalek');
    await Future.delayed(const Duration(milliseconds: 500));

    expect(cubit.state, isA<NeighborhoodListSuccess>().having((s) => s.neighborhoods, 'neighborhoods', [neighborhood1]));
  });

  test('search on an un-loaded cubit is a no-op', () async {
    cubit.search('zamalek');
    await Future.delayed(const Duration(milliseconds: 500));
    expect(cubit.state, isA<NeighborhoodListInitial>());
    verifyNever(() => repository.watchNeighborhoods(
          cityId: any(named: 'cityId'),
          search: any(named: 'search'),
          limit: any(named: 'limit'),
        ));
  });

  test('loadMore grows the limit and hasNextPage reflects the exact count', () async {
    stubNeighborhoods(limit: 20, neighborhoods: const [neighborhood1], total: 2);
    await cubit.load(7);
    expect((cubit.state as NeighborhoodListSuccess).hasNextPage, isTrue);

    stubNeighborhoods(limit: 40, neighborhoods: const [neighborhood1, neighborhood2], total: 2);

    await cubit.loadMore();

    final state = cubit.state as NeighborhoodListSuccess;
    expect(state.neighborhoods, [neighborhood1, neighborhood2]);
    expect(state.limit, 40);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    stubNeighborhoods(limit: 20, neighborhoods: const [neighborhood1], total: 1);
    await cubit.load(7);

    await cubit.loadMore();

    verifyNever(() => repository.watchNeighborhoods(cityId: 7, search: any(named: 'search'), limit: 40));
  });

  test('loadMore preserves the existing items/limit and resets isLoadingMore on failure', () async {
    stubNeighborhoods(limit: 20, neighborhoods: const [neighborhood1], total: 2);
    await cubit.load(7);

    when(() => repository.watchNeighborhoods(cityId: 7, search: null, limit: 40))
        .thenAnswer((_) => Stream.error(Exception('boom')));

    await cubit.loadMore();

    final state = cubit.state as NeighborhoodListSuccess;
    expect(state.neighborhoods, [neighborhood1]);
    expect(state.limit, 20);
    expect(state.hasNextPage, isTrue);
    expect(state.isLoadingMore, isFalse);
    expect(state.loadMoreErrorMessage, isNotNull);
    expect(state.loadMoreErrorId, 1);
  });

  test('refresh re-fetches counts and resubscribes at the current search/limit without a Loading flash', () async {
    stubNeighborhoods(limit: 20, neighborhoods: const [neighborhood1], total: 1);
    await cubit.load(7);

    stubNeighborhoods(limit: 20, neighborhoods: const [neighborhood1, neighborhood2], total: 2);

    final states = <dynamic>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.refresh();
    await sub.cancel();

    expect(states, isNot(contains(isA<NeighborhoodListLoading>())));
    expect(
      cubit.state,
      isA<NeighborhoodListSuccess>().having((s) => s.neighborhoods, 'neighborhoods', [neighborhood1, neighborhood2]),
    );
  });
}

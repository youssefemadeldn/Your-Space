import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/features/classification/data/datasources/base_neighborhood_data_source.dart';
import 'package:your_space_mobile/features/classification/data/datasources/neighborhood_local_data_source_impl.dart';
import 'package:your_space_mobile/features/classification/data/models/create_neighborhood_request.dart';
import 'package:your_space_mobile/features/classification/data/models/neighborhood_response.dart';
import 'package:your_space_mobile/features/classification/data/models/update_neighborhood_request.dart';
import 'package:your_space_mobile/features/classification/data/repositories/neighborhood_repository_impl.dart';

class MockBaseNeighborhoodDataSource extends Mock implements BaseNeighborhoodDataSource {}

class MockNeighborhoodLocalDataSourceImpl extends Mock implements NeighborhoodLocalDataSourceImpl {}

void main() {
  late MockBaseNeighborhoodDataSource remote;
  late MockNeighborhoodLocalDataSourceImpl local;
  late NeighborhoodRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const CreateNeighborhoodRequest(name: ''));
    registerFallbackValue(const UpdateNeighborhoodRequest(name: ''));
    registerFallbackValue(const Neighborhood(id: 0, cityId: 0, name: ''));
  });

  setUp(() {
    remote = MockBaseNeighborhoodDataSource();
    local = MockNeighborhoodLocalDataSourceImpl();
    repository = NeighborhoodRepositoryImpl(remote, local);
    when(() => local.saveNeighborhood(any())).thenAnswer((_) async {});
    when(() => local.deleteNeighborhoodLocal(any())).thenAnswer((_) async {});
  });

  test('getNeighborhoods maps a paginated response to a PaginatedResult of entities', () async {
    when(() => remote.getNeighborhoods(cityId: 7, search: any(named: 'search'), pageIndex: 1, pageSize: 20))
        .thenAnswer(
      (_) async => const Right(PaginatedResponse(
        items: [
          NeighborhoodResponse(id: 1, cityId: 7, name: 'Zamalek'),
          NeighborhoodResponse(id: 2, cityId: 7, name: 'Sarayat'),
        ],
        pageIndex: 1,
        totalPages: 1,
        totalItems: 2,
      )),
    );

    final result = await repository.getNeighborhoods(cityId: 7, pageIndex: 1, pageSize: 20);

    expect(result.isRight(), isTrue);
    final page = result.getOrElse(() => throw StateError('expected Right'));
    expect(page.items.map((n) => n.name), ['Zamalek', 'Sarayat']);
    expect(page.totalItems, 2);
  });

  test('getNeighborhoods propagates a failure unchanged', () async {
    const failure = NetworkFailure();
    when(() => remote.getNeighborhoods(cityId: 7, search: any(named: 'search'), pageIndex: 1, pageSize: 20))
        .thenAnswer((_) async => const Left(failure));

    final result = await repository.getNeighborhoods(cityId: 7, pageIndex: 1, pageSize: 20);

    expect(result, const Left(failure));
  });

  test('watchNeighborhoods delegates straight to the local data source', () {
    when(() => local.watchNeighborhoods(cityId: 7, search: 'za', limit: 20)).thenAnswer(
      (_) => Stream.value(const [Neighborhood(id: 1, cityId: 7, name: 'Zamalek')]),
    );

    final stream = repository.watchNeighborhoods(cityId: 7, search: 'za', limit: 20);

    expect(stream, emits(const [Neighborhood(id: 1, cityId: 7, name: 'Zamalek')]));
  });

  test('countNeighborhoods delegates straight to the local data source', () async {
    when(() => local.countNeighborhoods(cityId: 7, search: null)).thenAnswer((_) async => 5);

    final count = await repository.countNeighborhoods(cityId: 7);

    expect(count, 5);
  });

  group('createNeighborhood (transitional Tier 1 write path)', () {
    test('creates via the remote call and upserts the confirmed row locally on success', () async {
      when(() => remote.createNeighborhood(7, any())).thenAnswer(
        (_) async => const Right(NeighborhoodResponse(id: 5, cityId: 7, name: 'Zamalek')),
      );

      final result = await repository.createNeighborhood(cityId: 7, name: 'Zamalek');

      expect(result, const Right(Neighborhood(id: 5, cityId: 7, name: 'Zamalek')));
      verify(() => local.saveNeighborhood(const Neighborhood(id: 5, cityId: 7, name: 'Zamalek'))).called(1);
    });

    test('propagates a remote failure without touching the local store', () async {
      const failure = NetworkFailure();
      when(() => remote.createNeighborhood(7, any())).thenAnswer((_) async => const Left(failure));

      final result = await repository.createNeighborhood(cityId: 7, name: 'Zamalek');

      expect(result, const Left(failure));
      verifyNever(() => local.saveNeighborhood(any()));
    });
  });

  group('updateNeighborhood (transitional Tier 1 write path)', () {
    test('updates via the remote call and upserts the confirmed row locally on success', () async {
      when(() => remote.updateNeighborhood(7, 1, any())).thenAnswer(
        (_) async => const Right(NeighborhoodResponse(id: 1, cityId: 7, name: 'Zamalek (Updated)')),
      );

      final result = await repository.updateNeighborhood(cityId: 7, id: 1, name: 'Zamalek (Updated)');

      expect(result, const Right(Neighborhood(id: 1, cityId: 7, name: 'Zamalek (Updated)')));
      verify(() => local.saveNeighborhood(const Neighborhood(id: 1, cityId: 7, name: 'Zamalek (Updated)')))
          .called(1);
    });
  });

  group('deleteNeighborhood (transitional Tier 1 write path)', () {
    test('deletes via the remote call and hard-removes the local row on success', () async {
      when(() => remote.deleteNeighborhood(7, 1)).thenAnswer((_) async => const Right(unit));

      final result = await repository.deleteNeighborhood(cityId: 7, id: 1);

      expect(result, const Right(unit));
      verify(() => local.deleteNeighborhoodLocal(1)).called(1);
    });

    test('propagates a remote failure without touching the local store', () async {
      const failure = NetworkFailure();
      when(() => remote.deleteNeighborhood(7, 1)).thenAnswer((_) async => const Left(failure));

      final result = await repository.deleteNeighborhood(cityId: 7, id: 1);

      expect(result, const Left(failure));
      verifyNever(() => local.deleteNeighborhoodLocal(any()));
    });
  });
}

import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import 'package:your_space_mobile/features/classification/data/datasources/base_city_data_source.dart';
import 'package:your_space_mobile/features/classification/data/datasources/city_local_data_source_impl.dart';
import 'package:your_space_mobile/features/classification/data/models/city_changes_response.dart';
import 'package:your_space_mobile/features/classification/data/models/city_response.dart';
import 'package:your_space_mobile/features/classification/data/models/create_city_request.dart';
import 'package:your_space_mobile/features/classification/data/models/update_city_request.dart';
import 'package:your_space_mobile/features/classification/data/repositories/city_repository_impl.dart';

class MockBaseCityDataSource extends Mock implements BaseCityDataSource {}

class MockCityLocalDataSourceImpl extends Mock implements CityLocalDataSourceImpl {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockBaseCityDataSource remote;
  late MockCityLocalDataSourceImpl local;
  late MockSyncService syncService;
  late CityRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const City(id: 0, governorateId: 0, name: ''));
    registerFallbackValue(const CreateCityRequest(name: ''));
    registerFallbackValue(const UpdateCityRequest(name: ''));
    registerFallbackValue(const <City>[]);
  });

  setUp(() {
    remote = MockBaseCityDataSource();
    local = MockCityLocalDataSourceImpl();
    syncService = MockSyncService();
    repository = CityRepositoryImpl(remote, local, syncService);
    when(
      () => local.queueCityMutation(
        city: any(named: 'city'),
        operation: any(named: 'operation'),
        payloadJson: any(named: 'payloadJson'),
      ),
    ).thenAnswer((_) async => 99);
    when(() => local.queueDeletedCity(any(), payloadJson: any(named: 'payloadJson'))).thenAnswer((_) async {});
    when(() => local.applyCityChanges(upserts: any(named: 'upserts'), tombstoneIds: any(named: 'tombstoneIds')))
        .thenAnswer((_) async {});
    when(() => local.saveCitiesSyncCursor(any())).thenAnswer((_) async {});
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

  group('createCity (pure optimistic path)', () {
    test('queues a negative-id create via the outbox and returns immediately', () async {
      final result = await repository.createCity(governorateId: 7, name: 'Book club');

      expect(result.isRight(), isTrue);
      final city = result.getOrElse(() => throw StateError('expected Right'));
      expect(city.id, lessThan(0));
      expect(city.governorateId, 7);
      expect(city.name, 'Book club');

      final captured = verify(
        () => local.queueCityMutation(
          city: captureAny(named: 'city'),
          operation: captureAny(named: 'operation'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      expect((captured[0] as City).id, lessThan(0));
      expect(captured[1], 'create');
      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['governorateId'], 7);
      expect(payload['name'], 'Book club');

      verifyNever(() => remote.createCity(any(), any()));
      verifyNever(() => syncService.replayRow(any()));
    });
  });

  group('createCityAndSync', () {
    test('queues via the outbox then returns the real city on a successful immediate replay', () async {
      const realCity = City(id: 5, governorateId: 7, name: 'Book club');
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Right(realCity));

      final result = await repository.createCityAndSync(governorateId: 7, name: 'Book club');

      expect(result, const Right(realCity));
      verify(() => syncService.replayRow(99)).called(1);
    });

    test('the queued row is not rolled back when the immediate replay fails', () async {
      const failure = NetworkFailure();
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Left(failure));

      final result = await repository.createCityAndSync(governorateId: 7, name: 'Book club');

      expect(result, const Left(failure));
      verify(
        () => local.queueCityMutation(
          city: any(named: 'city'),
          operation: 'create',
          payloadJson: any(named: 'payloadJson'),
        ),
      ).called(1);
    });
  });

  group('updateCity (pure optimistic path)', () {
    test('queues an update against the given id via the outbox and returns immediately', () async {
      final result = await repository.updateCity(governorateId: 7, id: 1, name: 'Maadi (Updated)');

      expect(result, isA<Right<Failure, City>>());
      final captured = verify(
        () => local.queueCityMutation(
          city: captureAny(named: 'city'),
          operation: captureAny(named: 'operation'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      expect((captured[0] as City).id, 1);
      expect(captured[1], 'update');
      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['governorateId'], 7);
      expect(payload['name'], 'Maadi (Updated)');

      verifyNever(() => remote.updateCity(any(), any(), any()));
    });
  });

  group('deleteCity (pure optimistic path)', () {
    test('queues a delete via the outbox and returns immediately with no remote call', () async {
      final result = await repository.deleteCity(governorateId: 7, id: 1);

      expect(result, const Right(unit));
      final captured = verify(() => local.queueDeletedCity(captureAny(), payloadJson: captureAny(named: 'payloadJson')))
          .captured;
      expect(captured[0], 1);
      final payload = jsonDecode(captured[1] as String) as Map<String, dynamic>;
      expect(payload['governorateId'], 7);

      verifyNever(() => remote.deleteCity(any(), any()));
    });
  });

  group('refreshCities', () {
    test('single page, no more data: applies the page and persists its cursor', () async {
      when(() => local.getCitiesSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getCityChanges(since: 0, pageSize: 200)).thenAnswer(
        (_) async =>
            Right(CityChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [5], cursor: 137, hasMore: false)),
      );

      final result = await repository.refreshCities();

      expect(result, const Right(unit));
      final captured = verify(
        () => local.applyCityChanges(
          upserts: captureAny(named: 'upserts'),
          tombstoneIds: captureAny(named: 'tombstoneIds'),
        ),
      ).captured;
      expect((captured[0] as List<City>).map((c) => c.id), [1]);
      expect(captured[1], [5]);
      verify(() => local.saveCitiesSyncCursor(137)).called(1);
    });

    test('multi-page loop threads the returned cursor forward as the next since', () async {
      when(() => local.getCitiesSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getCityChanges(since: 0, pageSize: 200)).thenAnswer(
        (_) async =>
            Right(CityChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [], cursor: 50, hasMore: true)),
      );
      when(() => remote.getCityChanges(since: 50, pageSize: 200)).thenAnswer(
        (_) async =>
            Right(CityChangesResponse(upserts: [_toResponse(2)], tombstoneIds: const [], cursor: 90, hasMore: false)),
      );

      final result = await repository.refreshCities();

      expect(result, const Right(unit));
      verify(() => remote.getCityChanges(since: 0, pageSize: 200)).called(1);
      verify(() => remote.getCityChanges(since: 50, pageSize: 200)).called(1);
      verify(
        () => local.applyCityChanges(upserts: any(named: 'upserts'), tombstoneIds: any(named: 'tombstoneIds')),
      ).called(2);
      verify(() => local.saveCitiesSyncCursor(50)).called(1);
      verify(() => local.saveCitiesSyncCursor(90)).called(1);
    });

    test('resumes from a previously stored cursor', () async {
      when(() => local.getCitiesSyncCursor()).thenAnswer((_) async => 300);
      when(() => remote.getCityChanges(since: 300, pageSize: 200)).thenAnswer(
        (_) async => const Right(CityChangesResponse(upserts: [], tombstoneIds: [], cursor: 300, hasMore: false)),
      );

      final result = await repository.refreshCities();

      expect(result, const Right(unit));
      verify(() => remote.getCityChanges(since: 300, pageSize: 200)).called(1);
    });

    test(
      'stops and returns Left immediately on a failing page, preserving prior pages\' persisted cursor',
      () async {
        when(() => local.getCitiesSyncCursor()).thenAnswer((_) async => 0);
        when(() => remote.getCityChanges(since: 0, pageSize: 200)).thenAnswer(
          (_) async =>
              Right(CityChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [], cursor: 50, hasMore: true)),
        );
        const failure = NetworkFailure();
        when(() => remote.getCityChanges(since: 50, pageSize: 200)).thenAnswer((_) async => const Left(failure));

        final result = await repository.refreshCities();

        expect(result, const Left(failure));
        verify(() => local.saveCitiesSyncCursor(50)).called(1);
        verify(
          () => local.applyCityChanges(upserts: any(named: 'upserts'), tombstoneIds: any(named: 'tombstoneIds')),
        ).called(1);
        verify(() => remote.getCityChanges(since: 0, pageSize: 200)).called(1);
        verify(() => remote.getCityChanges(since: 50, pageSize: 200)).called(1);
        verifyNever(() => remote.getCityChanges(since: 90, pageSize: 200));
      },
    );

    test('stops after the defensive page cap when the server always says hasMore', () async {
      when(() => local.getCitiesSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getCityChanges(since: any(named: 'since'), pageSize: 200)).thenAnswer((invocation) async {
        final since = invocation.namedArguments[#since] as int;
        return Right(CityChangesResponse(upserts: const [], tombstoneIds: const [], cursor: since + 1, hasMore: true));
      });

      final result = await repository.refreshCities();

      expect(result, const Right(unit));
      verify(() => local.saveCitiesSyncCursor(any())).called(50);
    });
  });
}

CityResponse _toResponse(int id) => CityResponse(id: id, governorateId: 7, name: 'City $id');

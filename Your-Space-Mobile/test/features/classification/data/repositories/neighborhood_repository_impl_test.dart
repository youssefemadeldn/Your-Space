import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import 'package:your_space_mobile/features/classification/data/datasources/base_neighborhood_data_source.dart';
import 'package:your_space_mobile/features/classification/data/datasources/neighborhood_local_data_source_impl.dart';
import 'package:your_space_mobile/features/classification/data/models/create_neighborhood_request.dart';
import 'package:your_space_mobile/features/classification/data/models/neighborhood_changes_response.dart';
import 'package:your_space_mobile/features/classification/data/models/neighborhood_response.dart';
import 'package:your_space_mobile/features/classification/data/models/update_neighborhood_request.dart';
import 'package:your_space_mobile/features/classification/data/repositories/neighborhood_repository_impl.dart';

class MockBaseNeighborhoodDataSource extends Mock implements BaseNeighborhoodDataSource {}

class MockNeighborhoodLocalDataSourceImpl extends Mock implements NeighborhoodLocalDataSourceImpl {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockBaseNeighborhoodDataSource remote;
  late MockNeighborhoodLocalDataSourceImpl local;
  late MockSyncService syncService;
  late NeighborhoodRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const Neighborhood(id: 0, cityId: 0, name: ''));
    registerFallbackValue(const CreateNeighborhoodRequest(name: ''));
    registerFallbackValue(const UpdateNeighborhoodRequest(name: ''));
  });

  setUp(() {
    remote = MockBaseNeighborhoodDataSource();
    local = MockNeighborhoodLocalDataSourceImpl();
    syncService = MockSyncService();
    repository = NeighborhoodRepositoryImpl(remote, local, syncService);
    when(
      () => local.queueNeighborhoodMutation(
        neighborhood: any(named: 'neighborhood'),
        operation: any(named: 'operation'),
        payloadJson: any(named: 'payloadJson'),
      ),
    ).thenAnswer((_) async => 99);
    when(() => local.queueDeletedNeighborhood(any(), payloadJson: any(named: 'payloadJson'))).thenAnswer((_) async {});
    when(
      () => local.applyNeighborhoodChanges(upserts: any(named: 'upserts'), tombstoneIds: any(named: 'tombstoneIds')),
    ).thenAnswer((_) async {});
    when(() => local.saveNeighborhoodsSyncCursor(any())).thenAnswer((_) async {});
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

  group('createNeighborhood (pure optimistic path)', () {
    test('queues a negative-id create via the outbox and returns immediately', () async {
      final result = await repository.createNeighborhood(cityId: 7, name: 'Zamalek');

      expect(result.isRight(), isTrue);
      final neighborhood = result.getOrElse(() => throw StateError('expected Right'));
      expect(neighborhood.id, lessThan(0));
      expect(neighborhood.cityId, 7);
      expect(neighborhood.name, 'Zamalek');

      final captured = verify(
        () => local.queueNeighborhoodMutation(
          neighborhood: captureAny(named: 'neighborhood'),
          operation: captureAny(named: 'operation'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      expect((captured[0] as Neighborhood).id, lessThan(0));
      expect(captured[1], 'create');
      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['cityId'], 7);
      expect(payload['name'], 'Zamalek');

      verifyNever(() => remote.createNeighborhood(any(), any()));
      verifyNever(() => syncService.replayRow(any()));
    });
  });

  group('createNeighborhoodAndSync', () {
    test('queues via the outbox then returns the real neighborhood on a successful immediate replay', () async {
      const realNeighborhood = Neighborhood(id: 5, cityId: 7, name: 'Zamalek');
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Right(realNeighborhood));

      final result = await repository.createNeighborhoodAndSync(cityId: 7, name: 'Zamalek');

      expect(result, const Right(realNeighborhood));
      verify(() => syncService.replayRow(99)).called(1);
    });

    test('the queued row is not rolled back when the immediate replay fails', () async {
      const failure = NetworkFailure();
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Left(failure));

      final result = await repository.createNeighborhoodAndSync(cityId: 7, name: 'Zamalek');

      expect(result, const Left(failure));
      verify(
        () => local.queueNeighborhoodMutation(
          neighborhood: any(named: 'neighborhood'),
          operation: 'create',
          payloadJson: any(named: 'payloadJson'),
        ),
      ).called(1);
    });
  });

  group('updateNeighborhood (pure optimistic path)', () {
    test('queues an update against the given id via the outbox and returns immediately', () async {
      final result = await repository.updateNeighborhood(cityId: 7, id: 1, name: 'Zamalek (Updated)');

      expect(result, isA<Right<Failure, Neighborhood>>());
      final captured = verify(
        () => local.queueNeighborhoodMutation(
          neighborhood: captureAny(named: 'neighborhood'),
          operation: captureAny(named: 'operation'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      expect((captured[0] as Neighborhood).id, 1);
      expect(captured[1], 'update');
      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['cityId'], 7);
      expect(payload['name'], 'Zamalek (Updated)');

      verifyNever(() => remote.updateNeighborhood(any(), any(), any()));
    });
  });

  group('deleteNeighborhood (pure optimistic path)', () {
    test('queues a delete via the outbox and returns immediately with no remote call', () async {
      final result = await repository.deleteNeighborhood(cityId: 7, id: 1);

      expect(result, const Right(unit));
      final captured =
          verify(() => local.queueDeletedNeighborhood(captureAny(), payloadJson: captureAny(named: 'payloadJson')))
              .captured;
      expect(captured[0], 1);
      final payload = jsonDecode(captured[1] as String) as Map<String, dynamic>;
      expect(payload['cityId'], 7);

      verifyNever(() => remote.deleteNeighborhood(any(), any()));
    });
  });

  group('refreshNeighborhoods', () {
    test('single page, no more data: applies the page and persists its cursor', () async {
      when(() => local.getNeighborhoodsSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getNeighborhoodChanges(since: 0, pageSize: 200)).thenAnswer(
        (_) async => Right(
          NeighborhoodChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [5], cursor: 137, hasMore: false),
        ),
      );

      final result = await repository.refreshNeighborhoods();

      expect(result, const Right(unit));
      final captured = verify(
        () => local.applyNeighborhoodChanges(
          upserts: captureAny(named: 'upserts'),
          tombstoneIds: captureAny(named: 'tombstoneIds'),
        ),
      ).captured;
      expect((captured[0] as List<Neighborhood>).map((n) => n.id), [1]);
      expect(captured[1], [5]);
      verify(() => local.saveNeighborhoodsSyncCursor(137)).called(1);
    });

    test('multi-page loop threads the returned cursor forward as the next since', () async {
      when(() => local.getNeighborhoodsSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getNeighborhoodChanges(since: 0, pageSize: 200)).thenAnswer(
        (_) async => Right(
          NeighborhoodChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [], cursor: 50, hasMore: true),
        ),
      );
      when(() => remote.getNeighborhoodChanges(since: 50, pageSize: 200)).thenAnswer(
        (_) async => Right(
          NeighborhoodChangesResponse(upserts: [_toResponse(2)], tombstoneIds: const [], cursor: 90, hasMore: false),
        ),
      );

      final result = await repository.refreshNeighborhoods();

      expect(result, const Right(unit));
      verify(() => remote.getNeighborhoodChanges(since: 0, pageSize: 200)).called(1);
      verify(() => remote.getNeighborhoodChanges(since: 50, pageSize: 200)).called(1);
      verify(
        () => local.applyNeighborhoodChanges(
          upserts: any(named: 'upserts'),
          tombstoneIds: any(named: 'tombstoneIds'),
        ),
      ).called(2);
      verify(() => local.saveNeighborhoodsSyncCursor(50)).called(1);
      verify(() => local.saveNeighborhoodsSyncCursor(90)).called(1);
    });

    test('resumes from a previously stored cursor', () async {
      when(() => local.getNeighborhoodsSyncCursor()).thenAnswer((_) async => 300);
      when(() => remote.getNeighborhoodChanges(since: 300, pageSize: 200)).thenAnswer(
        (_) async =>
            const Right(NeighborhoodChangesResponse(upserts: [], tombstoneIds: [], cursor: 300, hasMore: false)),
      );

      final result = await repository.refreshNeighborhoods();

      expect(result, const Right(unit));
      verify(() => remote.getNeighborhoodChanges(since: 300, pageSize: 200)).called(1);
    });

    test(
      'stops and returns Left immediately on a failing page, preserving prior pages\' persisted cursor',
      () async {
        when(() => local.getNeighborhoodsSyncCursor()).thenAnswer((_) async => 0);
        when(() => remote.getNeighborhoodChanges(since: 0, pageSize: 200)).thenAnswer(
          (_) async => Right(
            NeighborhoodChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [], cursor: 50, hasMore: true),
          ),
        );
        const failure = NetworkFailure();
        when(() => remote.getNeighborhoodChanges(since: 50, pageSize: 200))
            .thenAnswer((_) async => const Left(failure));

        final result = await repository.refreshNeighborhoods();

        expect(result, const Left(failure));
        verify(() => local.saveNeighborhoodsSyncCursor(50)).called(1);
        verify(
          () => local.applyNeighborhoodChanges(
            upserts: any(named: 'upserts'),
            tombstoneIds: any(named: 'tombstoneIds'),
          ),
        ).called(1);
        verify(() => remote.getNeighborhoodChanges(since: 0, pageSize: 200)).called(1);
        verify(() => remote.getNeighborhoodChanges(since: 50, pageSize: 200)).called(1);
        verifyNever(() => remote.getNeighborhoodChanges(since: 90, pageSize: 200));
      },
    );

    test('stops after the defensive page cap when the server always says hasMore', () async {
      when(() => local.getNeighborhoodsSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getNeighborhoodChanges(since: any(named: 'since'), pageSize: 200))
          .thenAnswer((invocation) async {
        final since = invocation.namedArguments[#since] as int;
        return Right(
          NeighborhoodChangesResponse(upserts: const [], tombstoneIds: const [], cursor: since + 1, hasMore: true),
        );
      });

      final result = await repository.refreshNeighborhoods();

      expect(result, const Right(unit));
      verify(() => local.saveNeighborhoodsSyncCursor(any())).called(50);
    });
  });
}

NeighborhoodResponse _toResponse(int id) => NeighborhoodResponse(id: id, cityId: 7, name: 'Neighborhood $id');

import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import 'package:your_space_mobile/features/classification/data/datasources/base_governorate_data_source.dart';
import 'package:your_space_mobile/features/classification/data/datasources/governorate_local_data_source_impl.dart';
import 'package:your_space_mobile/features/classification/data/models/create_governorate_request.dart';
import 'package:your_space_mobile/features/classification/data/models/governorate_changes_response.dart';
import 'package:your_space_mobile/features/classification/data/models/governorate_response.dart';
import 'package:your_space_mobile/features/classification/data/repositories/governorate_repository_impl.dart';

class MockBaseGovernorateDataSource extends Mock implements BaseGovernorateDataSource {}

class MockGovernorateLocalDataSourceImpl extends Mock implements GovernorateLocalDataSourceImpl {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockBaseGovernorateDataSource remote;
  late MockGovernorateLocalDataSourceImpl local;
  late MockSyncService syncService;
  late GovernorateRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const Governorate(id: 0, name: ''));
    registerFallbackValue(const CreateGovernorateRequest(name: ''));
    registerFallbackValue(const <Governorate>[]);
  });

  setUp(() {
    remote = MockBaseGovernorateDataSource();
    local = MockGovernorateLocalDataSourceImpl();
    syncService = MockSyncService();
    repository = GovernorateRepositoryImpl(remote, local, syncService);
    when(
      () => local.queueGovernorateMutation(
        governorate: any(named: 'governorate'),
        operation: any(named: 'operation'),
        payloadJson: any(named: 'payloadJson'),
      ),
    ).thenAnswer((_) async => 99);
    when(() => local.applyGovernoratesSnapshot(any())).thenAnswer((_) async {});
    when(() => local.getGovernoratesSyncCursor()).thenAnswer((_) async => 0);
    when(
      () => local.applyGovernorateChanges(
        upserts: any(named: 'upserts'),
        tombstoneIds: any(named: 'tombstoneIds'),
      ),
    ).thenAnswer((_) async {});
    when(() => local.saveGovernoratesSyncCursor(any())).thenAnswer((_) async {});
  });

  test('getGovernorates maps a paginated response to a PaginatedResult of entities', () async {
    when(() => remote.getGovernorates(search: any(named: 'search'), pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResponse(
        items: [
          GovernorateResponse(id: 1, name: 'Cairo', isLocked: true),
          GovernorateResponse(id: 2, name: 'Giza', isLocked: true),
        ],
        pageIndex: 1,
        totalPages: 1,
        totalItems: 2,
      )),
    );

    final result = await repository.getGovernorates(pageIndex: 1, pageSize: 20);

    expect(result.isRight(), isTrue);
    final page = result.getOrElse(() => throw StateError('expected Right'));
    expect(page.items.map((g) => g.name), ['Cairo', 'Giza']);
    expect(page.totalItems, 2);
  });

  test('getGovernorates propagates a failure unchanged', () async {
    const failure = NetworkFailure();
    when(() => remote.getGovernorates(search: any(named: 'search'), pageIndex: 1, pageSize: 20))
        .thenAnswer((_) async => const Left(failure));

    final result = await repository.getGovernorates(pageIndex: 1, pageSize: 20);

    expect(result, const Left(failure));
  });

  test('watchGovernorates delegates straight to the local data source', () {
    when(() => local.watchGovernorates(search: 'cai', limit: 20)).thenAnswer(
      (_) => Stream.value(const [Governorate(id: 1, name: 'Cairo', isLocked: true)]),
    );

    final stream = repository.watchGovernorates(search: 'cai', limit: 20);

    expect(stream, emits(const [Governorate(id: 1, name: 'Cairo', isLocked: true)]));
  });

  test('countGovernorates delegates straight to the local data source', () async {
    when(() => local.countGovernorates(search: null)).thenAnswer((_) async => 27);

    final count = await repository.countGovernorates();

    expect(count, 27);
  });

  group('createGovernorate (pure optimistic path)', () {
    test('queues a negative-id create via the outbox and returns immediately', () async {
      final result = await repository.createGovernorate(name: 'Custom');

      expect(result.isRight(), isTrue);
      final governorate = result.getOrElse(() => throw StateError('expected Right'));
      expect(governorate.id, lessThan(0));
      expect(governorate.name, 'Custom');

      final captured = verify(
        () => local.queueGovernorateMutation(
          governorate: captureAny(named: 'governorate'),
          operation: captureAny(named: 'operation'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      expect((captured[0] as Governorate).id, lessThan(0));
      expect(captured[1], 'create');
      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['name'], 'Custom');

      verifyNever(() => remote.createGovernorate(any()));
      verifyNever(() => syncService.replayRow(any()));
    });
  });

  group('createGovernorateAndSync', () {
    test('queues via the outbox then returns the real governorate on a successful immediate replay',
        () async {
      const realGovernorate = Governorate(id: 5, name: 'Custom');
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Right(realGovernorate));

      final result = await repository.createGovernorateAndSync(name: 'Custom');

      expect(result, const Right(realGovernorate));
      verify(() => syncService.replayRow(99)).called(1);
    });

    test('the queued row is not rolled back when the immediate replay fails', () async {
      const failure = NetworkFailure();
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Left(failure));

      final result = await repository.createGovernorateAndSync(name: 'Custom');

      expect(result, const Left(failure));
      verify(
        () => local.queueGovernorateMutation(
          governorate: any(named: 'governorate'),
          operation: 'create',
          payloadJson: any(named: 'payloadJson'),
        ),
      ).called(1);
    });
  });

  group('refreshGovernorates', () {
    test('single page, no more data: applies the page and persists its cursor', () async {
      when(() => local.getGovernoratesSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getGovernorateChanges(since: 0, pageSize: 200)).thenAnswer(
        (_) async => Right(
          GovernorateChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [5], cursor: 137, hasMore: false),
        ),
      );

      final result = await repository.refreshGovernorates();

      expect(result, const Right(unit));
      final captured = verify(
        () => local.applyGovernorateChanges(
          upserts: captureAny(named: 'upserts'),
          tombstoneIds: captureAny(named: 'tombstoneIds'),
        ),
      ).captured;
      expect((captured[0] as List<Governorate>).map((g) => g.id), [1]);
      expect(captured[1], [5]);
      verify(() => local.saveGovernoratesSyncCursor(137)).called(1);
    });

    test('multi-page loop threads the returned cursor forward as the next since', () async {
      when(() => local.getGovernoratesSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getGovernorateChanges(since: 0, pageSize: 200)).thenAnswer(
        (_) async => Right(
          GovernorateChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [], cursor: 50, hasMore: true),
        ),
      );
      when(() => remote.getGovernorateChanges(since: 50, pageSize: 200)).thenAnswer(
        (_) async => Right(
          GovernorateChangesResponse(upserts: [_toResponse(2)], tombstoneIds: const [], cursor: 90, hasMore: false),
        ),
      );

      final result = await repository.refreshGovernorates();

      expect(result, const Right(unit));
      verify(() => remote.getGovernorateChanges(since: 0, pageSize: 200)).called(1);
      verify(() => remote.getGovernorateChanges(since: 50, pageSize: 200)).called(1);
      verify(
        () => local.applyGovernorateChanges(
          upserts: any(named: 'upserts'),
          tombstoneIds: any(named: 'tombstoneIds'),
        ),
      ).called(2);
      verify(() => local.saveGovernoratesSyncCursor(50)).called(1);
      verify(() => local.saveGovernoratesSyncCursor(90)).called(1);
    });

    test('resumes from a previously stored cursor', () async {
      when(() => local.getGovernoratesSyncCursor()).thenAnswer((_) async => 300);
      when(() => remote.getGovernorateChanges(since: 300, pageSize: 200)).thenAnswer(
        (_) async =>
            const Right(GovernorateChangesResponse(upserts: [], tombstoneIds: [], cursor: 300, hasMore: false)),
      );

      final result = await repository.refreshGovernorates();

      expect(result, const Right(unit));
      verify(() => remote.getGovernorateChanges(since: 300, pageSize: 200)).called(1);
    });

    test(
      'stops and returns Left immediately on a failing page, preserving prior pages\' persisted cursor',
      () async {
        when(() => local.getGovernoratesSyncCursor()).thenAnswer((_) async => 0);
        when(() => remote.getGovernorateChanges(since: 0, pageSize: 200)).thenAnswer(
          (_) async => Right(
            GovernorateChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [], cursor: 50, hasMore: true),
          ),
        );
        const failure = NetworkFailure();
        when(() => remote.getGovernorateChanges(since: 50, pageSize: 200))
            .thenAnswer((_) async => const Left(failure));

        final result = await repository.refreshGovernorates();

        expect(result, const Left(failure));
        verify(() => local.saveGovernoratesSyncCursor(50)).called(1);
        verify(
          () => local.applyGovernorateChanges(
            upserts: any(named: 'upserts'),
            tombstoneIds: any(named: 'tombstoneIds'),
          ),
        ).called(1);
        verify(() => remote.getGovernorateChanges(since: 0, pageSize: 200)).called(1);
        verify(() => remote.getGovernorateChanges(since: 50, pageSize: 200)).called(1);
        verifyNever(() => remote.getGovernorateChanges(since: 90, pageSize: 200));
      },
    );

    test('stops after the defensive page cap when the server always says hasMore', () async {
      when(() => local.getGovernoratesSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getGovernorateChanges(since: any(named: 'since'), pageSize: 200))
          .thenAnswer((invocation) async {
        final since = invocation.namedArguments[#since] as int;
        return Right(
          GovernorateChangesResponse(upserts: const [], tombstoneIds: const [], cursor: since + 1, hasMore: true),
        );
      });

      final result = await repository.refreshGovernorates();

      expect(result, const Right(unit));
      verify(() => local.saveGovernoratesSyncCursor(any())).called(50);
    });
  });
}

GovernorateResponse _toResponse(int id) => GovernorateResponse(id: id, name: 'Governorate $id', isLocked: true);

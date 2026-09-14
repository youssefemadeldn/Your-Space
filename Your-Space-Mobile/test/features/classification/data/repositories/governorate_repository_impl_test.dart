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
    test('loops every remote page and upserts the concatenated, mapped entities', () async {
      when(() => remote.getGovernorates(pageIndex: 1, pageSize: 200)).thenAnswer(
        (_) async =>
            Right(PaginatedResponse(items: [_toResponse(1)], pageIndex: 1, totalPages: 2, totalItems: 2)),
      );
      when(() => remote.getGovernorates(pageIndex: 2, pageSize: 200)).thenAnswer(
        (_) async =>
            Right(PaginatedResponse(items: [_toResponse(2)], pageIndex: 2, totalPages: 2, totalItems: 2)),
      );

      final result = await repository.refreshGovernorates();

      expect(result, const Right(unit));
      final captured =
          verify(() => local.applyGovernoratesSnapshot(captureAny())).captured.single as List<Governorate>;
      expect(captured.map((g) => g.id), [1, 2]);
    });

    test('stops and returns Left immediately on a failing page, without saving anything', () async {
      const failure = NetworkFailure();
      when(() => remote.getGovernorates(pageIndex: 1, pageSize: 200)).thenAnswer((_) async => const Left(failure));

      final result = await repository.refreshGovernorates();

      expect(result, const Left(failure));
      verifyNever(() => local.applyGovernoratesSnapshot(any()));
    });
  });
}

GovernorateResponse _toResponse(int id) => GovernorateResponse(id: id, name: 'Governorate $id', isLocked: true);

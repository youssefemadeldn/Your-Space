import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import 'package:your_space_mobile/features/classification/data/datasources/base_subgroup_data_source.dart';
import 'package:your_space_mobile/features/classification/data/datasources/subgroup_local_data_source_impl.dart';
import 'package:your_space_mobile/features/classification/data/models/create_subgroup_request.dart';
import 'package:your_space_mobile/features/classification/data/models/subgroup_response.dart';
import 'package:your_space_mobile/features/classification/data/models/update_subgroup_request.dart';
import 'package:your_space_mobile/features/classification/data/repositories/subgroup_repository_impl.dart';

class MockBaseSubGroupDataSource extends Mock implements BaseSubGroupDataSource {}

class MockSubGroupLocalDataSourceImpl extends Mock implements SubGroupLocalDataSourceImpl {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockBaseSubGroupDataSource remote;
  late MockSubGroupLocalDataSourceImpl local;
  late MockSyncService syncService;
  late SubGroupRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const SubGroup(id: 0, groupId: 0, name: ''));
    registerFallbackValue(const CreateSubGroupRequest(name: ''));
    registerFallbackValue(const UpdateSubGroupRequest(name: ''));
    registerFallbackValue(const <SubGroup>[]);
  });

  setUp(() {
    remote = MockBaseSubGroupDataSource();
    local = MockSubGroupLocalDataSourceImpl();
    syncService = MockSyncService();
    repository = SubGroupRepositoryImpl(remote, local, syncService);
    when(
      () => local.queueSubGroupMutation(
        subGroup: any(named: 'subGroup'),
        operation: any(named: 'operation'),
        payloadJson: any(named: 'payloadJson'),
      ),
    ).thenAnswer((_) async => 99);
    when(() => local.queueDeletedSubGroup(any(), payloadJson: any(named: 'payloadJson'))).thenAnswer((_) async {});
  });

  test('getSubGroups maps a paginated response to a PaginatedResult of entities', () async {
    when(() => remote.getSubGroups(groupId: 7, search: any(named: 'search'), pageIndex: 1, pageSize: 20))
        .thenAnswer(
      (_) async => const Right(PaginatedResponse(
        items: [
          SubGroupResponse(id: 1, groupId: 7, name: 'Immediate Family'),
          SubGroupResponse(id: 2, groupId: 7, name: 'University Friends'),
        ],
        pageIndex: 1,
        totalPages: 1,
        totalItems: 2,
      )),
    );

    final result = await repository.getSubGroups(groupId: 7, pageIndex: 1, pageSize: 20);

    expect(result.isRight(), isTrue);
    final page = result.getOrElse(() => throw StateError('expected Right'));
    expect(page.items.map((s) => s.name), ['Immediate Family', 'University Friends']);
    expect(page.totalItems, 2);
  });

  test('getSubGroups propagates a failure unchanged', () async {
    const failure = NetworkFailure();
    when(() => remote.getSubGroups(groupId: 7, search: any(named: 'search'), pageIndex: 1, pageSize: 20))
        .thenAnswer((_) async => const Left(failure));

    final result = await repository.getSubGroups(groupId: 7, pageIndex: 1, pageSize: 20);

    expect(result, const Left(failure));
  });

  test('watchSubGroups delegates straight to the local data source', () {
    when(() => local.watchSubGroups(groupId: 7, search: 'im', limit: 20)).thenAnswer(
      (_) => Stream.value(const [SubGroup(id: 1, groupId: 7, name: 'Immediate Family')]),
    );

    final stream = repository.watchSubGroups(groupId: 7, search: 'im', limit: 20);

    expect(stream, emits(const [SubGroup(id: 1, groupId: 7, name: 'Immediate Family')]));
  });

  test('countSubGroups delegates straight to the local data source', () async {
    when(() => local.countSubGroups(groupId: 7, search: null)).thenAnswer((_) async => 5);

    final count = await repository.countSubGroups(groupId: 7);

    expect(count, 5);
  });

  group('createSubGroup (pure optimistic path)', () {
    test('queues a negative-id create via the outbox and returns immediately', () async {
      final result = await repository.createSubGroup(groupId: 7, name: 'Book club');

      expect(result.isRight(), isTrue);
      final subGroup = result.getOrElse(() => throw StateError('expected Right'));
      expect(subGroup.id, lessThan(0));
      expect(subGroup.groupId, 7);
      expect(subGroup.name, 'Book club');

      final captured = verify(
        () => local.queueSubGroupMutation(
          subGroup: captureAny(named: 'subGroup'),
          operation: captureAny(named: 'operation'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      expect((captured[0] as SubGroup).id, lessThan(0));
      expect(captured[1], 'create');
      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['groupId'], 7);
      expect(payload['name'], 'Book club');

      verifyNever(() => remote.createSubGroup(any(), any()));
      verifyNever(() => syncService.replayRow(any()));
    });
  });

  group('createSubGroupAndSync', () {
    test('queues via the outbox then returns the real subgroup on a successful immediate replay', () async {
      const realSubGroup = SubGroup(id: 5, groupId: 7, name: 'Book club');
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Right(realSubGroup));

      final result = await repository.createSubGroupAndSync(groupId: 7, name: 'Book club');

      expect(result, const Right(realSubGroup));
      verify(() => syncService.replayRow(99)).called(1);
    });

    test('the queued row is not rolled back when the immediate replay fails', () async {
      const failure = NetworkFailure();
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Left(failure));

      final result = await repository.createSubGroupAndSync(groupId: 7, name: 'Book club');

      expect(result, const Left(failure));
      verify(
        () => local.queueSubGroupMutation(
          subGroup: any(named: 'subGroup'),
          operation: 'create',
          payloadJson: any(named: 'payloadJson'),
        ),
      ).called(1);
    });
  });

  group('updateSubGroup (pure optimistic path)', () {
    test('queues an update against the given id via the outbox and returns immediately', () async {
      final result = await repository.updateSubGroup(groupId: 7, id: 1, name: 'Immediate Family (Updated)');

      expect(result, isA<Right<Failure, SubGroup>>());
      final captured = verify(
        () => local.queueSubGroupMutation(
          subGroup: captureAny(named: 'subGroup'),
          operation: captureAny(named: 'operation'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      expect((captured[0] as SubGroup).id, 1);
      expect(captured[1], 'update');
      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['groupId'], 7);
      expect(payload['name'], 'Immediate Family (Updated)');

      verifyNever(() => remote.updateSubGroup(any(), any(), any()));
    });
  });

  group('deleteSubGroup (pure optimistic path)', () {
    test('queues a delete via the outbox and returns immediately with no remote call', () async {
      final result = await repository.deleteSubGroup(groupId: 7, id: 1);

      expect(result, const Right(unit));
      final captured =
          verify(() => local.queueDeletedSubGroup(captureAny(), payloadJson: captureAny(named: 'payloadJson')))
              .captured;
      expect(captured[0], 1);
      final payload = jsonDecode(captured[1] as String) as Map<String, dynamic>;
      expect(payload['groupId'], 7);

      verifyNever(() => remote.deleteSubGroup(any(), any()));
    });
  });

  group('refreshSubGroups', () {
    test('loops every remote page and applies the concatenated, mapped entities as a snapshot', () async {
      when(() => local.applySubGroupsSnapshot(any())).thenAnswer((_) async {});
      when(() => remote.getAllMineSubGroups(search: any(named: 'search'), pageIndex: 1, pageSize: 200)).thenAnswer(
        (_) async => const Right(PaginatedResponse(
          items: [SubGroupResponse(id: 1, groupId: 7, name: 'Immediate Family')],
          pageIndex: 1,
          totalPages: 2,
          totalItems: 2,
        )),
      );
      when(() => remote.getAllMineSubGroups(search: any(named: 'search'), pageIndex: 2, pageSize: 200)).thenAnswer(
        (_) async => const Right(PaginatedResponse(
          items: [SubGroupResponse(id: 2, groupId: 7, name: 'University Friends')],
          pageIndex: 2,
          totalPages: 2,
          totalItems: 2,
        )),
      );

      final result = await repository.refreshSubGroups();

      expect(result, const Right(unit));
      final captured = verify(() => local.applySubGroupsSnapshot(captureAny())).captured.single as List<SubGroup>;
      expect(captured.map((s) => s.id), [1, 2]);
    });

    test('stops and returns Left immediately on a failing page, without saving anything', () async {
      const failure = NetworkFailure();
      when(() => remote.getAllMineSubGroups(search: any(named: 'search'), pageIndex: 1, pageSize: 200))
          .thenAnswer((_) async => const Left(failure));

      final result = await repository.refreshSubGroups();

      expect(result, const Left(failure));
      verifyNever(() => local.applySubGroupsSnapshot(any()));
    });
  });
}

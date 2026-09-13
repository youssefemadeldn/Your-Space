import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import 'package:your_space_mobile/features/groups/data/datasources/base_group_data_source.dart';
import 'package:your_space_mobile/features/groups/data/datasources/group_local_data_source_impl.dart';
import 'package:your_space_mobile/features/groups/data/models/create_group_request.dart';
import 'package:your_space_mobile/features/groups/data/models/group_response.dart';
import 'package:your_space_mobile/features/groups/data/models/update_group_request.dart';
import 'package:your_space_mobile/features/groups/data/repositories/group_repository_impl.dart';

class MockBaseGroupDataSource extends Mock implements BaseGroupDataSource {}

class MockGroupLocalDataSourceImpl extends Mock implements GroupLocalDataSourceImpl {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockBaseGroupDataSource remote;
  late MockGroupLocalDataSourceImpl local;
  late MockSyncService syncService;
  late GroupRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const Group(id: 0, name: ''));
    registerFallbackValue(const CreateGroupRequest(name: ''));
    registerFallbackValue(const UpdateGroupRequest(id: 0, name: ''));
    registerFallbackValue(const <Group>[]);
  });

  setUp(() {
    remote = MockBaseGroupDataSource();
    local = MockGroupLocalDataSourceImpl();
    syncService = MockSyncService();
    repository = GroupRepositoryImpl(remote, local, syncService);
    when(() => local.saveGroup(any())).thenAnswer((_) async {});
    when(
      () => local.queueGroupMutation(
        group: any(named: 'group'),
        operation: any(named: 'operation'),
        payloadJson: any(named: 'payloadJson'),
      ),
    ).thenAnswer((_) async => 99);
    when(() => local.applyGroupsSnapshot(any())).thenAnswer((_) async {});
  });

  test('getGroups maps a paginated response to a PaginatedResult of entities', () async {
    when(() => remote.getGroups(search: any(named: 'search'), pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResponse(
        items: [GroupResponse(id: 1, name: 'Family'), GroupResponse(id: 2, name: 'Close friends')],
        pageIndex: 1,
        totalPages: 1,
        totalItems: 2,
      )),
    );

    final result = await repository.getGroups(pageIndex: 1, pageSize: 20);

    expect(result.isRight(), isTrue);
    final page = result.getOrElse(() => throw StateError('expected Right'));
    expect(page.items.map((g) => g.name), ['Family', 'Close friends']);
    expect(page.totalItems, 2);
  });

  test('getGroups propagates a failure unchanged', () async {
    const failure = NetworkFailure();
    when(() => remote.getGroups(search: any(named: 'search'), pageIndex: 1, pageSize: 20))
        .thenAnswer((_) async => const Left(failure));

    final result = await repository.getGroups(pageIndex: 1, pageSize: 20);

    expect(result, const Left(failure));
  });

  test('watchGroups delegates straight to the local data source', () {
    when(() => local.watchGroups(search: 'fam', limit: 20)).thenAnswer(
      (_) => Stream.value(const [Group(id: 1, name: 'Family')]),
    );

    final stream = repository.watchGroups(search: 'fam', limit: 20);

    expect(stream, emits(const [Group(id: 1, name: 'Family')]));
  });

  test('countGroups delegates straight to the local data source', () async {
    when(() => local.countGroups(search: null)).thenAnswer((_) async => 7);

    final count = await repository.countGroups();

    expect(count, 7);
  });

  group('createGroup (pure optimistic path)', () {
    test('queues a negative-id create via the outbox and returns immediately', () async {
      final result = await repository.createGroup(name: 'Book club');

      expect(result.isRight(), isTrue);
      final group = result.getOrElse(() => throw StateError('expected Right'));
      expect(group.id, lessThan(0));
      expect(group.name, 'Book club');

      final captured = verify(
        () => local.queueGroupMutation(
          group: captureAny(named: 'group'),
          operation: captureAny(named: 'operation'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      expect((captured[0] as Group).id, lessThan(0));
      expect(captured[1], 'create');
      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['name'], 'Book club');

      verifyNever(() => remote.createGroup(any()));
      verifyNever(() => syncService.replayRow(any()));
    });
  });

  group('updateGroup (pure optimistic path)', () {
    test('queues an update against the given id via the outbox and returns immediately', () async {
      final result = await repository.updateGroup(id: 1, name: 'The Family');

      expect(result, isA<Right<Failure, Group>>());
      final captured = verify(
        () => local.queueGroupMutation(
          group: captureAny(named: 'group'),
          operation: captureAny(named: 'operation'),
          payloadJson: captureAny(named: 'payloadJson'),
        ),
      ).captured;
      expect((captured[0] as Group).id, 1);
      expect(captured[1], 'update');
      final payload = jsonDecode(captured[2] as String) as Map<String, dynamic>;
      expect(payload['id'], 1);

      verifyNever(() => remote.updateGroup(any()));
      verifyNever(() => syncService.replayRow(any()));
    });
  });

  group('createGroupAndSync', () {
    test('queues via the outbox then returns the real group on a successful immediate replay', () async {
      const realGroup = Group(id: 5, name: 'Book club');
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Right(realGroup));

      final result = await repository.createGroupAndSync(name: 'Book club');

      expect(result, const Right(realGroup));
      verify(() => syncService.replayRow(99)).called(1);
    });

    test('the queued row is not rolled back when the immediate replay fails', () async {
      const failure = NetworkFailure();
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Left(failure));

      final result = await repository.createGroupAndSync(name: 'Book club');

      expect(result, const Left(failure));
      verify(
        () => local.queueGroupMutation(
          group: any(named: 'group'),
          operation: 'create',
          payloadJson: any(named: 'payloadJson'),
        ),
      ).called(1);
    });
  });

  group('refreshGroups', () {
    test('loops every remote page and upserts the concatenated, mapped entities', () async {
      when(() => remote.getGroups(pageIndex: 1, pageSize: 200)).thenAnswer(
        (_) async => Right(PaginatedResponse(items: [_toResponse(1)], pageIndex: 1, totalPages: 2, totalItems: 2)),
      );
      when(() => remote.getGroups(pageIndex: 2, pageSize: 200)).thenAnswer(
        (_) async => Right(PaginatedResponse(items: [_toResponse(2)], pageIndex: 2, totalPages: 2, totalItems: 2)),
      );

      final result = await repository.refreshGroups();

      expect(result, const Right(unit));
      final captured = verify(() => local.applyGroupsSnapshot(captureAny())).captured.single as List<Group>;
      expect(captured.map((g) => g.id), [1, 2]);
    });

    test('stops and returns Left immediately on a failing page, without saving anything', () async {
      const failure = NetworkFailure();
      when(() => remote.getGroups(pageIndex: 1, pageSize: 200)).thenAnswer((_) async => const Left(failure));

      final result = await repository.refreshGroups();

      expect(result, const Left(failure));
      verifyNever(() => local.applyGroupsSnapshot(any()));
    });
  });
}

GroupResponse _toResponse(int id) => GroupResponse(id: id, name: 'Group $id');

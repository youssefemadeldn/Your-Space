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
import 'package:your_space_mobile/features/groups/data/models/group_changes_response.dart';
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
    when(() => local.getGroupsSyncCursor()).thenAnswer((_) async => 0);
    when(
      () => local.applyGroupChanges(
        upserts: any(named: 'upserts'),
        tombstoneIds: any(named: 'tombstoneIds'),
      ),
    ).thenAnswer((_) async {});
    when(() => local.saveGroupsSyncCursor(any())).thenAnswer((_) async {});
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
    test('single page, no more data: applies the page and persists its cursor', () async {
      when(() => local.getGroupsSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getGroupChanges(since: 0, pageSize: 200)).thenAnswer(
        (_) async =>
            Right(GroupChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [5], cursor: 137, hasMore: false)),
      );

      final result = await repository.refreshGroups();

      expect(result, const Right(unit));
      final captured = verify(
        () => local.applyGroupChanges(
          upserts: captureAny(named: 'upserts'),
          tombstoneIds: captureAny(named: 'tombstoneIds'),
        ),
      ).captured;
      expect((captured[0] as List<Group>).map((g) => g.id), [1]);
      expect(captured[1], [5]);
      verify(() => local.saveGroupsSyncCursor(137)).called(1);
    });

    test('multi-page loop threads the returned cursor forward as the next since', () async {
      when(() => local.getGroupsSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getGroupChanges(since: 0, pageSize: 200)).thenAnswer(
        (_) async =>
            Right(GroupChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [], cursor: 50, hasMore: true)),
      );
      when(() => remote.getGroupChanges(since: 50, pageSize: 200)).thenAnswer(
        (_) async =>
            Right(GroupChangesResponse(upserts: [_toResponse(2)], tombstoneIds: const [], cursor: 90, hasMore: false)),
      );

      final result = await repository.refreshGroups();

      expect(result, const Right(unit));
      verify(() => remote.getGroupChanges(since: 0, pageSize: 200)).called(1);
      verify(() => remote.getGroupChanges(since: 50, pageSize: 200)).called(1);
      verify(
        () => local.applyGroupChanges(upserts: any(named: 'upserts'), tombstoneIds: any(named: 'tombstoneIds')),
      ).called(2);
      verify(() => local.saveGroupsSyncCursor(50)).called(1);
      verify(() => local.saveGroupsSyncCursor(90)).called(1);
    });

    test('resumes from a previously stored cursor', () async {
      when(() => local.getGroupsSyncCursor()).thenAnswer((_) async => 300);
      when(() => remote.getGroupChanges(since: 300, pageSize: 200)).thenAnswer(
        (_) async => const Right(GroupChangesResponse(upserts: [], tombstoneIds: [], cursor: 300, hasMore: false)),
      );

      final result = await repository.refreshGroups();

      expect(result, const Right(unit));
      verify(() => remote.getGroupChanges(since: 300, pageSize: 200)).called(1);
    });

    test(
      'stops and returns Left immediately on a failing page, preserving prior pages\' persisted cursor',
      () async {
        when(() => local.getGroupsSyncCursor()).thenAnswer((_) async => 0);
        when(() => remote.getGroupChanges(since: 0, pageSize: 200)).thenAnswer(
          (_) async =>
              Right(GroupChangesResponse(upserts: [_toResponse(1)], tombstoneIds: const [], cursor: 50, hasMore: true)),
        );
        const failure = NetworkFailure();
        when(() => remote.getGroupChanges(since: 50, pageSize: 200)).thenAnswer((_) async => const Left(failure));

        final result = await repository.refreshGroups();

        expect(result, const Left(failure));
        verify(() => local.saveGroupsSyncCursor(50)).called(1);
        verify(
          () => local.applyGroupChanges(upserts: any(named: 'upserts'), tombstoneIds: any(named: 'tombstoneIds')),
        ).called(1);
        verify(() => remote.getGroupChanges(since: 0, pageSize: 200)).called(1);
        verify(() => remote.getGroupChanges(since: 50, pageSize: 200)).called(1);
        verifyNever(() => remote.getGroupChanges(since: 90, pageSize: 200));
      },
    );

    test('stops after the defensive page cap when the server always says hasMore', () async {
      when(() => local.getGroupsSyncCursor()).thenAnswer((_) async => 0);
      when(() => remote.getGroupChanges(since: any(named: 'since'), pageSize: 200)).thenAnswer((invocation) async {
        final since = invocation.namedArguments[#since] as int;
        return Right(GroupChangesResponse(upserts: const [], tombstoneIds: const [], cursor: since + 1, hasMore: true));
      });

      final result = await repository.refreshGroups();

      expect(result, const Right(unit));
      verify(() => local.saveGroupsSyncCursor(any())).called(50);
    });
  });
}

GroupResponse _toResponse(int id) => GroupResponse(id: id, name: 'Group $id');

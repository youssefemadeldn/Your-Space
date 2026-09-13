import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/groups/data/datasources/base_group_data_source.dart';
import 'package:your_space_mobile/features/groups/data/datasources/group_local_data_source_impl.dart';
import 'package:your_space_mobile/features/groups/data/models/create_group_request.dart';
import 'package:your_space_mobile/features/groups/data/models/group_response.dart';
import 'package:your_space_mobile/features/groups/data/models/update_group_request.dart';
import 'package:your_space_mobile/features/groups/data/sync/group_outbox_replayer.dart';

class MockBaseGroupDataSource extends Mock implements BaseGroupDataSource {}

class MockGroupLocalDataSourceImpl extends Mock implements GroupLocalDataSourceImpl {}

OutboxTableData _row({
  int id = 1,
  int entityId = -1,
  required String operation,
  required String payloadJson,
}) =>
    OutboxTableData(
      id: id,
      entityType: 'group',
      entityId: entityId,
      operation: operation,
      payloadJson: payloadJson,
      createdAt: DateTime(2026),
      retryCount: 0,
    );

const _groupResponse = GroupResponse(id: 999, name: 'Book club');

void main() {
  late MockBaseGroupDataSource remote;
  late MockGroupLocalDataSourceImpl local;
  late GroupOutboxReplayer replayer;

  setUpAll(() {
    registerFallbackValue(const CreateGroupRequest(name: ''));
    registerFallbackValue(const UpdateGroupRequest(id: 0, name: ''));
    registerFallbackValue(const Group(id: 0, name: ''));
  });

  setUp(() {
    remote = MockBaseGroupDataSource();
    local = MockGroupLocalDataSourceImpl();
    replayer = GroupOutboxReplayer(remote, local);
    when(() => local.reconcileCreatedGroup(
          tempId: any(named: 'tempId'),
          realGroup: any(named: 'realGroup'),
          replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
        )).thenAnswer((_) async {});
    when(() => local.confirmSyncedGroup(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
  });

  test('entityType is group', () {
    expect(replayer.entityType, 'group');
  });

  group('create', () {
    test('success decodes the payload, calls remote.createGroup, and reconciles the temp id', () async {
      when(() => remote.createGroup(any())).thenAnswer((_) async => const Right(_groupResponse));
      final row = _row(id: 5, entityId: -42, operation: 'create', payloadJson: '{"name":"Book club"}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      final captured = verify(() => remote.createGroup(captureAny())).captured.single as CreateGroupRequest;
      expect(captured.name, 'Book club');
      verify(
        () => local.reconcileCreatedGroup(tempId: -42, realGroup: _groupResponse.toEntity(), replayedOutboxRowId: 5),
      ).called(1);
    });

    test('failure returns Left and never reconciles', () async {
      const failure = NetworkFailure();
      when(() => remote.createGroup(any())).thenAnswer((_) async => const Left(failure));
      final row = _row(operation: 'create', payloadJson: '{"name":"Book club"}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.reconcileCreatedGroup(
            tempId: any(named: 'tempId'),
            realGroup: any(named: 'realGroup'),
            replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
          ));
    });
  });

  group('update', () {
    test('success decodes the payload, calls remote.updateGroup, and confirms the sync', () async {
      when(() => remote.updateGroup(any())).thenAnswer((_) async => const Right(_groupResponse));
      final row = _row(id: 7, entityId: 999, operation: 'update', payloadJson: '{"id":999,"name":"Book club"}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      final captured = verify(() => remote.updateGroup(captureAny())).captured.single as UpdateGroupRequest;
      expect(captured.id, 999);
      verify(() => local.confirmSyncedGroup(_groupResponse.toEntity(), replayedOutboxRowId: 7)).called(1);
    });

    test('failure returns Left and never confirms', () async {
      const failure = ServerFailure(statusCode: 500, message: 'boom');
      when(() => remote.updateGroup(any())).thenAnswer((_) async => const Left(failure));
      final row = _row(operation: 'update', payloadJson: '{"id":999,"name":"Book club"}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.confirmSyncedGroup(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')));
    });
  });

  test('an unrecognized operation returns Left without throwing', () async {
    final row = _row(operation: 'delete', payloadJson: '{}');

    final result = await replayer.replay(row);

    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(remote);
  });
}

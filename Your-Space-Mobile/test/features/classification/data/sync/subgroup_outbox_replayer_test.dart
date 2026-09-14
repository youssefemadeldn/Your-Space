import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/data/datasources/base_subgroup_data_source.dart';
import 'package:your_space_mobile/features/classification/data/datasources/subgroup_local_data_source_impl.dart';
import 'package:your_space_mobile/features/classification/data/models/create_subgroup_request.dart';
import 'package:your_space_mobile/features/classification/data/models/subgroup_response.dart';
import 'package:your_space_mobile/features/classification/data/models/update_subgroup_request.dart';
import 'package:your_space_mobile/features/classification/data/sync/subgroup_outbox_replayer.dart';

class MockBaseSubGroupDataSource extends Mock implements BaseSubGroupDataSource {}

class MockSubGroupLocalDataSourceImpl extends Mock implements SubGroupLocalDataSourceImpl {}

OutboxTableData _row({
  int id = 1,
  int entityId = -1,
  required String operation,
  required String payloadJson,
}) =>
    OutboxTableData(
      id: id,
      entityType: 'subgroup',
      entityId: entityId,
      operation: operation,
      payloadJson: payloadJson,
      createdAt: DateTime(2026),
      retryCount: 0,
    );

const _subGroupResponse = SubGroupResponse(id: 999, groupId: 7, name: 'Immediate Family');

void main() {
  late MockBaseSubGroupDataSource remote;
  late MockSubGroupLocalDataSourceImpl local;
  late SubGroupOutboxReplayer replayer;

  setUpAll(() {
    registerFallbackValue(const CreateSubGroupRequest(name: ''));
    registerFallbackValue(const UpdateSubGroupRequest(name: ''));
    registerFallbackValue(const SubGroup(id: 0, groupId: 0, name: ''));
  });

  setUp(() {
    remote = MockBaseSubGroupDataSource();
    local = MockSubGroupLocalDataSourceImpl();
    replayer = SubGroupOutboxReplayer(remote, local);
    when(() => local.reconcileCreatedSubGroup(
          tempId: any(named: 'tempId'),
          realSubGroup: any(named: 'realSubGroup'),
          replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
        )).thenAnswer((_) async {});
    when(() => local.confirmSyncedSubGroup(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
    when(() => local.confirmDeletedSubGroup(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
  });

  test('entityType is subgroup', () {
    expect(replayer.entityType, 'subgroup');
  });

  group('create', () {
    test('success decodes the payload, calls remote.createSubGroup with the parent id, and reconciles the temp id',
        () async {
      when(() => remote.createSubGroup(7, any())).thenAnswer((_) async => const Right(_subGroupResponse));
      final row = _row(
        id: 5,
        entityId: -42,
        operation: 'create',
        payloadJson: '{"groupId":7,"name":"Immediate Family"}',
      );

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      final captured =
          verify(() => remote.createSubGroup(7, captureAny())).captured.single as CreateSubGroupRequest;
      expect(captured.name, 'Immediate Family');
      verify(
        () => local.reconcileCreatedSubGroup(
          tempId: -42,
          realSubGroup: _subGroupResponse.toEntity(),
          replayedOutboxRowId: 5,
        ),
      ).called(1);
    });

    test('failure returns Left and never reconciles', () async {
      const failure = NetworkFailure();
      when(() => remote.createSubGroup(7, any())).thenAnswer((_) async => const Left(failure));
      final row = _row(operation: 'create', payloadJson: '{"groupId":7,"name":"Immediate Family"}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.reconcileCreatedSubGroup(
            tempId: any(named: 'tempId'),
            realSubGroup: any(named: 'realSubGroup'),
            replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
          ));
    });
  });

  group('update', () {
    test('success decodes the payload, calls remote.updateSubGroup with the entity id, and confirms the sync',
        () async {
      when(() => remote.updateSubGroup(7, 999, any())).thenAnswer((_) async => const Right(_subGroupResponse));
      final row = _row(
        id: 7,
        entityId: 999,
        operation: 'update',
        payloadJson: '{"groupId":7,"name":"Immediate Family"}',
      );

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      final captured =
          verify(() => remote.updateSubGroup(7, 999, captureAny())).captured.single as UpdateSubGroupRequest;
      expect(captured.name, 'Immediate Family');
      verify(() => local.confirmSyncedSubGroup(_subGroupResponse.toEntity(), replayedOutboxRowId: 7)).called(1);
    });

    test('failure returns Left and never confirms', () async {
      const failure = ServerFailure(statusCode: 500, message: 'boom');
      when(() => remote.updateSubGroup(7, 999, any())).thenAnswer((_) async => const Left(failure));
      final row = _row(entityId: 999, operation: 'update', payloadJson: '{"groupId":7,"name":"Immediate Family"}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.confirmSyncedSubGroup(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')));
    });
  });

  group('delete', () {
    test('success calls remote.deleteSubGroup with the parent id and hard-removes the local row', () async {
      when(() => remote.deleteSubGroup(7, 999)).thenAnswer((_) async => const Right(unit));
      final row = _row(id: 11, entityId: 999, operation: 'delete', payloadJson: '{"groupId":7}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      verify(() => remote.deleteSubGroup(7, 999)).called(1);
      verify(() => local.confirmDeletedSubGroup(999, replayedOutboxRowId: 11)).called(1);
    });

    test('failure returns Left and never confirms', () async {
      const failure = NetworkFailure();
      when(() => remote.deleteSubGroup(7, 999)).thenAnswer((_) async => const Left(failure));
      final row = _row(entityId: 999, operation: 'delete', payloadJson: '{"groupId":7}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.confirmDeletedSubGroup(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')));
    });
  });

  test('an unrecognized operation returns Left without throwing', () async {
    final row = _row(operation: 'unknown', payloadJson: '{"groupId":7}');

    final result = await replayer.replay(row);

    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(remote);
  });
}

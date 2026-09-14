import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/people/data/datasources/person_local_data_source_impl.dart';
import 'package:your_space_mobile/features/people/data/datasources/person_remote_data_source_impl.dart';
import 'package:your_space_mobile/features/people/data/models/create_person_request.dart';
import 'package:your_space_mobile/features/people/data/models/person_response.dart';
import 'package:your_space_mobile/features/people/data/models/update_person_request.dart';
import 'package:your_space_mobile/features/people/data/sync/person_outbox_replayer.dart';

class MockPersonRemoteDataSourceImpl extends Mock implements PersonRemoteDataSourceImpl {}

class MockPersonLocalDataSourceImpl extends Mock implements PersonLocalDataSourceImpl {}

OutboxTableData _row({
  int id = 1,
  int entityId = -1,
  required String operation,
  required String payloadJson,
}) =>
    OutboxTableData(
      id: id,
      entityType: 'person',
      entityId: entityId,
      operation: operation,
      payloadJson: payloadJson,
      createdAt: DateTime(2026),
      retryCount: 0,
    );

const _personResponse = PersonResponse(
  id: 999,
  name: 'Nadia',
  gender: Gender.female,
  groupId: 1,
  groupName: 'Family',
  governorateId: 1,
  governorateName: 'Cairo',
  hasReciprocityHistory: false,
);

void main() {
  late MockPersonRemoteDataSourceImpl remote;
  late MockPersonLocalDataSourceImpl local;
  late PersonOutboxReplayer replayer;

  setUpAll(() {
    registerFallbackValue(
      const CreatePersonRequest(name: '', gender: Gender.male, groupId: 0, governorateId: 0),
    );
    registerFallbackValue(
      const UpdatePersonRequest(id: 0, name: '', gender: Gender.male, groupId: 0, governorateId: 0),
    );
    registerFallbackValue(const Person(id: 0, name: '', gender: Gender.male, groupId: 0, groupName: '', governorateId: 0, governorateName: ''));
  });

  setUp(() {
    remote = MockPersonRemoteDataSourceImpl();
    local = MockPersonLocalDataSourceImpl();
    replayer = PersonOutboxReplayer(remote, local);
    when(() => local.reconcileCreatedPerson(
          tempId: any(named: 'tempId'),
          realPerson: any(named: 'realPerson'),
          replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
        )).thenAnswer((_) async {});
    when(() => local.confirmSyncedPerson(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
  });

  test('entityType is person', () {
    expect(replayer.entityType, 'person');
  });

  group('create', () {
    test('success decodes the payload, calls remote.createPerson, and reconciles the temp id', () async {
      when(() => remote.createPerson(any())).thenAnswer((_) async => const Right(_personResponse));
      final row = _row(id: 5, entityId: -42, operation: 'create', payloadJson: '{"name":"Nadia","groupId":1,"governorateId":1,"gender":"Female"}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      final captured = verify(() => remote.createPerson(captureAny())).captured.single as CreatePersonRequest;
      expect(captured.name, 'Nadia');
      verify(() => local.reconcileCreatedPerson(tempId: -42, realPerson: _personResponse.toEntity(), replayedOutboxRowId: 5))
          .called(1);
    });

    test('failure returns Left and never reconciles', () async {
      const failure = NetworkFailure();
      when(() => remote.createPerson(any())).thenAnswer((_) async => const Left(failure));
      final row = _row(operation: 'create', payloadJson: '{"name":"Nadia","groupId":1,"governorateId":1,"gender":"Female"}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.reconcileCreatedPerson(
            tempId: any(named: 'tempId'),
            realPerson: any(named: 'realPerson'),
            replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
          ));
    });
  });

  group('update', () {
    test('success decodes the payload, calls remote.updatePerson, and confirms the sync', () async {
      when(() => remote.updatePerson(any())).thenAnswer((_) async => const Right(_personResponse));
      final row = _row(
        id: 7,
        entityId: 999,
        operation: 'update',
        payloadJson: '{"id":999,"name":"Nadia","groupId":1,"governorateId":1,"gender":"Female"}',
      );

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      final captured = verify(() => remote.updatePerson(captureAny())).captured.single as UpdatePersonRequest;
      expect(captured.id, 999);
      verify(() => local.confirmSyncedPerson(_personResponse.toEntity(), replayedOutboxRowId: 7)).called(1);
    });

    test('failure returns Left and never confirms', () async {
      const failure = ServerFailure(statusCode: 500, message: 'boom');
      when(() => remote.updatePerson(any())).thenAnswer((_) async => const Left(failure));
      final row = _row(
        operation: 'update',
        payloadJson: '{"id":999,"name":"Nadia","groupId":1,"governorateId":1,"gender":"Female"}',
      );

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.confirmSyncedPerson(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')));
    });
  });

  test('an unrecognized operation returns Left without throwing', () async {
    final row = _row(operation: 'delete', payloadJson: '{}');

    final result = await replayer.replay(row);

    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(remote);
  });
}

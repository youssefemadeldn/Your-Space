import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/people/data/datasources/base_person_relationship_data_source.dart';
import 'package:your_space_mobile/features/people/data/datasources/person_relationship_local_data_source_impl.dart';
import 'package:your_space_mobile/features/people/data/models/create_person_relationship_request.dart';
import 'package:your_space_mobile/features/people/data/models/create_person_relationship_response.dart';
import 'package:your_space_mobile/features/people/data/sync/person_relationship_outbox_replayer.dart';
import 'package:your_space_mobile/core/entities/person_relationship.dart';

class MockBasePersonRelationshipDataSource extends Mock implements BasePersonRelationshipDataSource {}

class MockPersonRelationshipLocalDataSourceImpl extends Mock implements PersonRelationshipLocalDataSourceImpl {}

OutboxTableData _row({
  int id = 1,
  int entityId = -1,
  required String operation,
  required String payloadJson,
}) =>
    OutboxTableData(
      id: id,
      entityType: 'personRelationship',
      entityId: entityId,
      operation: operation,
      payloadJson: payloadJson,
      createdAt: DateTime(2026),
      retryCount: 0,
    );

const _tempForward = PersonRelationship(
  id: -1,
  personId: 10,
  relatedPersonId: 20,
  relatedPersonName: 'Ahmed',
  relationType: RelationType.father,
  inverseId: -2,
);
const _tempInverse = PersonRelationship(
  id: -2,
  personId: 20,
  relatedPersonId: 10,
  relatedPersonName: 'Youssef',
  relationType: RelationType.son,
  inverseId: -1,
);

const _response = CreatePersonRelationshipResponse(
  id: 100,
  personId: 10,
  relatedPersonId: 20,
  relatedPersonName: 'Ahmed',
  relationType: RelationType.father,
  inverseId: 200,
  inverseRelationType: RelationType.son,
);

void main() {
  late MockBasePersonRelationshipDataSource remote;
  late MockPersonRelationshipLocalDataSourceImpl local;
  late PersonRelationshipOutboxReplayer replayer;

  setUpAll(() {
    registerFallbackValue(const CreatePersonRelationshipRequest(relatedPersonId: 0, relationType: RelationType.father));
    registerFallbackValue(const PersonRelationship(id: 0, personId: 0, relatedPersonId: 0, relatedPersonName: '', relationType: RelationType.father));
  });

  setUp(() {
    remote = MockBasePersonRelationshipDataSource();
    local = MockPersonRelationshipLocalDataSourceImpl();
    replayer = PersonRelationshipOutboxReplayer(remote, local);
    when(() => local.confirmSyncedPersonRelationshipPair(
          tempForwardId: any(named: 'tempForwardId'),
          tempInverseId: any(named: 'tempInverseId'),
          realForward: any(named: 'realForward'),
          realInverse: any(named: 'realInverse'),
          replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
        )).thenAnswer((_) async {});
    when(() => local.confirmDeletedPersonRelationship(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
  });

  test('entityType is personRelationship', () {
    expect(replayer.entityType, 'personRelationship');
  });

  group('create', () {
    test('success reconciles both the forward and inverse temp ids', () async {
      when(() => remote.createRelationship(10, any())).thenAnswer((_) async => const Right(_response));
      when(() => local.getLocalRelationship(-1)).thenAnswer((_) async => _tempForward);
      when(() => local.getLocalRelationship(-2)).thenAnswer((_) async => _tempInverse);
      final row = _row(id: 5, entityId: -1, operation: 'create', payloadJson: '{"personId":10,"relatedPersonId":20,"relationType":"Father"}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      final captured = verify(
        () => local.confirmSyncedPersonRelationshipPair(
          tempForwardId: -1,
          tempInverseId: -2,
          realForward: captureAny(named: 'realForward'),
          realInverse: captureAny(named: 'realInverse'),
          replayedOutboxRowId: 5,
        ),
      ).captured;
      final realForward = captured[0] as PersonRelationship;
      final realInverse = captured[1] as PersonRelationship;
      expect(realForward.id, 100);
      expect(realInverse.id, 200);
      expect(realInverse.relatedPersonName, 'Youssef');
    });

    test('failure returns Left and never reconciles', () async {
      const failure = NetworkFailure();
      when(() => remote.createRelationship(10, any())).thenAnswer((_) async => const Left(failure));
      final row = _row(entityId: -1, operation: 'create', payloadJson: '{"personId":10,"relatedPersonId":20,"relationType":"Father"}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.confirmSyncedPersonRelationshipPair(
            tempForwardId: any(named: 'tempForwardId'),
            tempInverseId: any(named: 'tempInverseId'),
            realForward: any(named: 'realForward'),
            realInverse: any(named: 'realInverse'),
            replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
          ));
    });
  });

  group('delete', () {
    test('success calls deleteRelationship and confirms the delete', () async {
      when(() => remote.deleteRelationship(10, 1)).thenAnswer((_) async => const Right(unit));
      final row = _row(id: 8, entityId: 1, operation: 'delete', payloadJson: '{"personId":10}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      verify(() => local.confirmDeletedPersonRelationship(1, replayedOutboxRowId: 8)).called(1);
    });
  });

  test('an unrecognized operation returns Left without throwing', () async {
    final row = _row(operation: 'bogus', payloadJson: '{"personId":10}');

    final result = await replayer.replay(row);

    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(remote);
  });
}

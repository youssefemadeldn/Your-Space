import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/person_relationship.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';
import 'package:your_space_mobile/features/people/data/datasources/person_relationship_local_data_source_impl.dart';

void main() {
  late AppDatabase database;
  late PersonRelationshipLocalDataSourceImpl dataSource;

  const forward = PersonRelationship(
    id: 1,
    personId: 10,
    relatedPersonId: 20,
    relatedPersonName: 'Ahmed',
    relationType: RelationType.father,
    inverseId: 2,
  );
  const inverse = PersonRelationship(
    id: 2,
    personId: 20,
    relatedPersonId: 10,
    relatedPersonName: 'Youssef',
    relationType: RelationType.son,
    inverseId: 1,
  );

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = PersonRelationshipLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('watchRelationships emits the seeded set scoped to personId', () async {
    await dataSource.saveRelationships(const [forward, inverse]);

    final relationships = await dataSource.watchRelationships(personId: 10, limit: 10).first;

    expect(relationships.map((r) => r.id), [1]);
  });

  test('getLocalRelationship reads a single row by id', () async {
    await dataSource.saveRelationships(const [forward]);

    final row = await dataSource.getLocalRelationship(1);

    expect(row?.relatedPersonName, 'Ahmed');
    expect(row?.inverseId, 2);
  });

  test('queuePersonRelationshipPair inserts both rows and appends one outbox row', () async {
    final rowId = await dataSource.queuePersonRelationshipPair(
      forward: const PersonRelationship(id: -1, personId: 10, relatedPersonId: 20, relatedPersonName: 'Ahmed', relationType: RelationType.father, inverseId: -2),
      inverse: const PersonRelationship(id: -2, personId: 20, relatedPersonId: 10, relatedPersonName: 'Youssef', relationType: RelationType.son, inverseId: -1),
      payloadJson: '{"personId":10,"relatedPersonId":20,"relationType":"Father"}',
    );

    final forwardRow = await dataSource.getLocalRelationship(-1);
    final inverseRow = await dataSource.getLocalRelationship(-2);
    expect(forwardRow?.relatedPersonName, 'Ahmed');
    expect(inverseRow?.relatedPersonName, 'Youssef');
    final outboxRows = await database.select(database.outboxTable).get();
    expect(outboxRows.single.id, rowId);
    expect(outboxRows.single.entityType, 'personRelationship');
  });

  test('confirmSyncedPersonRelationshipPair resolves both temp ids to real ids', () async {
    final rowId = await dataSource.queuePersonRelationshipPair(
      forward: const PersonRelationship(id: -1, personId: 10, relatedPersonId: 20, relatedPersonName: 'Ahmed', relationType: RelationType.father, inverseId: -2),
      inverse: const PersonRelationship(id: -2, personId: 20, relatedPersonId: 10, relatedPersonName: 'Youssef', relationType: RelationType.son, inverseId: -1),
      payloadJson: '{}',
    );

    await dataSource.confirmSyncedPersonRelationshipPair(
      tempForwardId: -1,
      tempInverseId: -2,
      realForward: forward,
      realInverse: inverse,
      replayedOutboxRowId: rowId,
    );

    expect(await dataSource.getLocalRelationship(-1), isNull);
    expect(await dataSource.getLocalRelationship(-2), isNull);
    final realForwardRow = await dataSource.getLocalRelationship(1);
    final realInverseRow = await dataSource.getLocalRelationship(2);
    expect(realForwardRow?.relatedPersonName, 'Ahmed');
    expect(realInverseRow?.relatedPersonName, 'Youssef');
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  group('queueDeletedPersonRelationship', () {
    test('a real (positive) id tombstones both the row and its paired inverse, queues one outbox row', () async {
      await dataSource.saveRelationships(const [forward, inverse]);

      await dataSource.queueDeletedPersonRelationship(1, payloadJson: '{"personId":10}');

      expect(await dataSource.watchRelationships(personId: 10, limit: 10).first, isEmpty);
      expect(await dataSource.watchRelationships(personId: 20, limit: 10).first, isEmpty);
      final outboxRows = await database.select(database.outboxTable).get();
      expect(outboxRows.single.operation, 'delete');
      expect(outboxRows.single.entityId, 1);
    });

    test('a never-synced temp (negative) id removes both rows locally with no outbox row', () async {
      final rowId = await dataSource.queuePersonRelationshipPair(
        forward: const PersonRelationship(id: -1, personId: 10, relatedPersonId: 20, relatedPersonName: 'Ahmed', relationType: RelationType.father, inverseId: -2),
        inverse: const PersonRelationship(id: -2, personId: 20, relatedPersonId: 10, relatedPersonName: 'Youssef', relationType: RelationType.son, inverseId: -1),
        payloadJson: '{}',
      );

      await dataSource.queueDeletedPersonRelationship(-1, payloadJson: '{"personId":10}');

      expect(await dataSource.watchAllRelationships(limit: 10).first, isEmpty);
      final outboxRows = await database.select(database.outboxTable).get();
      expect(outboxRows.where((r) => r.id == rowId), isEmpty);
    });
  });

  test('confirmDeletedPersonRelationship hard-removes both the tombstoned row and its inverse', () async {
    await dataSource.saveRelationships(const [forward, inverse]);
    await dataSource.queueDeletedPersonRelationship(1, payloadJson: '{"personId":10}');
    final outboxRowId = (await database.select(database.outboxTable).get()).single.id;

    await dataSource.confirmDeletedPersonRelationship(1, replayedOutboxRowId: outboxRowId);

    expect(await database.select(database.personRelationshipsTable).get(), isEmpty);
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  group('applyPersonRelationshipsSnapshot (permanent full-refetch-as-delta)', () {
    test('upserts a server row that is not already dirty locally', () async {
      await dataSource.applyPersonRelationshipsSnapshot(const [forward]);

      final row = await dataSource.getLocalRelationship(1);
      expect(row?.relatedPersonName, 'Ahmed');
    });

    test('a clean positive-id row absent from the server list is soft-tombstoned', () async {
      await dataSource.saveRelationships(const [forward]);

      await dataSource.applyPersonRelationshipsSnapshot(const []);

      expect(await dataSource.watchRelationships(personId: 10, limit: 10).first, isEmpty);
    });
  });
}

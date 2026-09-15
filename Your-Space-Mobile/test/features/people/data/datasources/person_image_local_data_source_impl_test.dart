import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/person_image_ref.dart';
import 'package:your_space_mobile/features/people/data/datasources/person_image_local_data_source_impl.dart';

void main() {
  late AppDatabase database;
  late PersonImageLocalDataSourceImpl dataSource;

  const image1 = PersonImageRef(id: 1, personId: 10, objectKey: 'people/10/a.jpg', isPrimary: true);
  const image2 = PersonImageRef(id: 2, personId: 10, objectKey: 'people/10/b.jpg', isPrimary: false);

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = PersonImageLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('watchImages emits the seeded set scoped to personId', () async {
    await dataSource.saveImages(const [
      image1,
      image2,
      PersonImageRef(id: 3, personId: 20, objectKey: 'people/20/a.jpg', isPrimary: true),
    ]);

    final images = await dataSource.watchImages(personId: 10, limit: 10).first;

    expect(images.map((i) => i.id), containsAll([1, 2]));
  });

  test('queuePersonImageUpload appends one outbox row with no drift row inserted', () async {
    final rowId = await dataSource.queuePersonImageUpload(
      tempId: -1,
      payloadJson: '{"personId":10,"localFilePath":"/tmp/a.jpg","isPrimary":false}',
    );

    final outboxRows = await database.select(database.outboxTable).get();
    expect(outboxRows.single.id, rowId);
    expect(outboxRows.single.entityType, 'personImage');
    expect(outboxRows.single.entityId, -1);
    expect(await database.select(database.personImagesTable).get(), isEmpty);
  });

  test('confirmUploadedImage inserts the real row and removes the outbox row', () async {
    final rowId = await dataSource.queuePersonImageUpload(tempId: -1, payloadJson: '{}');

    await dataSource.confirmUploadedImage(image1, replayedOutboxRowId: rowId);

    final images = await dataSource.watchImages(personId: 10, limit: 10).first;
    expect(images.single.objectKey, 'people/10/a.jpg');
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  test('queueDeletedImage tombstones the row and queues one outbox row', () async {
    await dataSource.saveImages(const [image1]);

    await dataSource.queueDeletedImage(1, payloadJson: '{"personId":10}');

    expect(await dataSource.watchImages(personId: 10, limit: 10).first, isEmpty);
    final outboxRows = await database.select(database.outboxTable).get();
    expect(outboxRows.single.operation, 'delete');
  });

  test('confirmDeletedImage hard-removes the tombstoned row and its outbox row', () async {
    await dataSource.saveImages(const [image1]);
    await dataSource.queueDeletedImage(1, payloadJson: '{"personId":10}');
    final outboxRowId = (await database.select(database.outboxTable).get()).single.id;

    await dataSource.confirmDeletedImage(1, replayedOutboxRowId: outboxRowId);

    expect(await database.select(database.personImagesTable).get(), isEmpty);
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  test('queueSetPrimary clears isPrimary on siblings and sets it on the target, queues one outbox row', () async {
    await dataSource.saveImages(const [image1, image2]);

    await dataSource.queueSetPrimary(personId: 10, id: 2, payloadJson: '{"personId":10}');

    final images = await dataSource.watchImages(personId: 10, limit: 10).first;
    expect(images.singleWhere((i) => i.id == 1).isPrimary, isFalse);
    expect(images.singleWhere((i) => i.id == 2).isPrimary, isTrue);
    final outboxRows = await database.select(database.outboxTable).get();
    expect(outboxRows.single.operation, 'update');
  });

  test('confirmSyncedPrimary clears isDirty and removes the outbox row', () async {
    await dataSource.saveImages(const [image1, image2]);
    final rowId = await dataSource.queueSetPrimary(personId: 10, id: 2, payloadJson: '{"personId":10}');

    await dataSource.confirmSyncedPrimary(2, replayedOutboxRowId: rowId);

    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  group('applyPersonImagesSnapshot (permanent full-refetch-as-delta)', () {
    test('upserts a server row that is not already dirty locally', () async {
      await dataSource.applyPersonImagesSnapshot(const [image1]);

      final images = await dataSource.watchImages(personId: 10, limit: 10).first;
      expect(images.single.objectKey, 'people/10/a.jpg');
    });

    test('a clean positive-id row absent from the server list is soft-tombstoned', () async {
      await dataSource.saveImages(const [image1]);

      await dataSource.applyPersonImagesSnapshot(const []);

      expect(await dataSource.watchImages(personId: 10, limit: 10).first, isEmpty);
    });
  });
}

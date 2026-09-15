import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/person_image_ref.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/people/data/datasources/base_person_image_data_source.dart';
import 'package:your_space_mobile/features/people/data/datasources/person_image_local_data_source_impl.dart';
import 'package:your_space_mobile/features/people/data/models/person_image_response.dart';
import 'package:your_space_mobile/features/people/data/sync/person_image_outbox_replayer.dart';

class MockBasePersonImageDataSource extends Mock implements BasePersonImageDataSource {}

class MockPersonImageLocalDataSourceImpl extends Mock implements PersonImageLocalDataSourceImpl {}

OutboxTableData _row({
  int id = 1,
  int entityId = -1,
  required String operation,
  required String payloadJson,
}) =>
    OutboxTableData(
      id: id,
      entityType: 'personImage',
      entityId: entityId,
      operation: operation,
      payloadJson: payloadJson,
      createdAt: DateTime(2026),
      retryCount: 0,
    );

void main() {
  late MockBasePersonImageDataSource remote;
  late MockPersonImageLocalDataSourceImpl local;
  late PersonImageOutboxReplayer replayer;
  late Directory tempDir;

  setUpAll(() {
    registerFallbackValue(const PersonImageRef(id: 0, personId: 0, objectKey: '', isPrimary: false));
    registerFallbackValue(File(''));
  });

  setUp(() async {
    remote = MockBasePersonImageDataSource();
    local = MockPersonImageLocalDataSourceImpl();
    replayer = PersonImageOutboxReplayer(remote, local);
    tempDir = await Directory.systemTemp.createTemp('person_image_outbox_replayer_test');
    when(() => local.confirmUploadedImage(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
    when(() => local.discardOutboxRow(any())).thenAnswer((_) async {});
    when(() => local.confirmSyncedPrimary(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
    when(() => local.confirmDeletedImage(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
  });

  tearDown(() => tempDir.delete(recursive: true));

  test('entityType is personImage', () {
    expect(replayer.entityType, 'personImage');
  });

  group('create', () {
    test('success uploads the staged file and confirms with the real image', () async {
      final filePath = '${tempDir.path}/staged.jpg';
      await File(filePath).writeAsBytes([1, 2, 3]);
      when(() => remote.uploadImage(10, any())).thenAnswer(
        (_) async => const Right(PersonImageResponse(id: 5, url: 'https://cdn/a.jpg', isPrimary: true, objectKey: 'people/10/a.jpg')),
      );
      final row = _row(
        id: 7,
        entityId: -1,
        operation: 'create',
        payloadJson: '{"personId":10,"localFilePath":"$filePath","isPrimary":false}',
      );

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      final captured = verify(
        () => local.confirmUploadedImage(captureAny(), replayedOutboxRowId: 7),
      ).captured;
      final ref = captured.single as PersonImageRef;
      expect(ref.id, 5);
      expect(ref.objectKey, 'people/10/a.jpg');
    });

    test('a missing staged file discards the outbox row without calling remote', () async {
      final row = _row(
        entityId: -1,
        operation: 'create',
        payloadJson: '{"personId":10,"localFilePath":"${'${tempDir.path}/gone.jpg'}","isPrimary":false}',
      );

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      verify(() => local.discardOutboxRow(row.id)).called(1);
      verifyZeroInteractions(remote);
    });

    test('a remote failure returns Left and never confirms', () async {
      final filePath = '${tempDir.path}/staged.jpg';
      await File(filePath).writeAsBytes([1, 2, 3]);
      const failure = NetworkFailure();
      when(() => remote.uploadImage(10, any())).thenAnswer((_) async => const Left(failure));
      final row = _row(
        entityId: -1,
        operation: 'create',
        payloadJson: '{"personId":10,"localFilePath":"$filePath","isPrimary":false}',
      );

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.confirmUploadedImage(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')));
    });
  });

  group('update (set primary)', () {
    test('success calls setPrimary and confirms the sync', () async {
      when(() => remote.setPrimary(10, 5)).thenAnswer(
        (_) async => const Right(PersonImageResponse(id: 5, url: 'https://cdn/a.jpg', isPrimary: true)),
      );
      final row = _row(id: 8, entityId: 5, operation: 'update', payloadJson: '{"personId":10}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      verify(() => local.confirmSyncedPrimary(5, replayedOutboxRowId: 8)).called(1);
    });
  });

  group('delete', () {
    test('success calls deleteImage and confirms the delete', () async {
      when(() => remote.deleteImage(10, 5)).thenAnswer((_) async => const Right(unit));
      final row = _row(id: 9, entityId: 5, operation: 'delete', payloadJson: '{"personId":10}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      verify(() => local.confirmDeletedImage(5, replayedOutboxRowId: 9)).called(1);
    });
  });

  test('an unrecognized operation returns Left without throwing', () async {
    final row = _row(operation: 'bogus', payloadJson: '{"personId":10}');

    final result = await replayer.replay(row);

    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(remote);
  });
}

import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/person_image.dart';
import 'package:your_space_mobile/core/entities/person_image_ref.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import 'package:your_space_mobile/features/people/data/datasources/base_person_image_data_source.dart';
import 'package:your_space_mobile/features/people/data/datasources/person_image_local_data_source_impl.dart';
import 'package:your_space_mobile/features/people/data/models/person_image_profile_response.dart';
import 'package:your_space_mobile/features/people/data/models/person_image_response.dart';
import 'package:your_space_mobile/features/people/data/repositories/person_image_repository_impl.dart';

class MockBasePersonImageDataSource extends Mock implements BasePersonImageDataSource {}

class MockPersonImageLocalDataSourceImpl extends Mock implements PersonImageLocalDataSourceImpl {}

class MockSyncService extends Mock implements SyncService {}

class FakeFile extends Fake implements File {
  @override
  String get path => '/tmp/staged.jpg';
}

void main() {
  late MockBasePersonImageDataSource remote;
  late MockPersonImageLocalDataSourceImpl local;
  late MockSyncService syncService;
  late PersonImageRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const PersonImageRef(id: 0, personId: 0, objectKey: '', isPrimary: false));
  });

  setUp(() {
    remote = MockBasePersonImageDataSource();
    local = MockPersonImageLocalDataSourceImpl();
    syncService = MockSyncService();
    repository = PersonImageRepositoryImpl(remote, local, syncService);
    when(() => local.queuePersonImageUpload(tempId: any(named: 'tempId'), payloadJson: any(named: 'payloadJson')))
        .thenAnswer((_) async => 99);
    when(() => local.queueDeletedImage(any(), payloadJson: any(named: 'payloadJson'))).thenAnswer((_) async {});
    when(
      () => local.queueSetPrimary(
        personId: any(named: 'personId'),
        id: any(named: 'id'),
        payloadJson: any(named: 'payloadJson'),
      ),
    ).thenAnswer((_) async => 100);
    when(() => local.applyPersonImagesSnapshot(any())).thenAnswer((_) async {});
  });

  test('getImages delegates straight to the network — never cached', () async {
    when(() => remote.getImages(10)).thenAnswer(
      (_) async => const Right([PersonImageResponse(id: 1, url: 'https://cdn/a.jpg', isPrimary: true)]),
    );

    final result = await repository.getImages(10);

    expect(result.isRight(), isTrue);
    final images = result.getOrElse(() => throw StateError('expected Right'));
    expect(images.single.url, 'https://cdn/a.jpg');
  });

  group('uploadImage (queue-then-sync, mirrors createCityAndSync)', () {
    test('queues via the outbox, replays immediately, and returns the real confirmed image', () async {
      const realImage = PersonImage(id: 5, url: 'https://cdn/a.jpg', isPrimary: true);
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Right(realImage));

      final result = await repository.uploadImage(personId: 10, file: FakeFile());

      expect(result, const Right(realImage));
      verify(() => syncService.replayRow(99)).called(1);
      final captured = verify(
        () => local.queuePersonImageUpload(tempId: captureAny(named: 'tempId'), payloadJson: captureAny(named: 'payloadJson')),
      ).captured;
      expect(captured[0], lessThan(0));
    });

    test('propagates a failure from the immediate replay, but the row stays queued', () async {
      const failure = NetworkFailure();
      when(() => syncService.replayRow(99)).thenAnswer((_) async => const Left(failure));

      final result = await repository.uploadImage(personId: 10, file: FakeFile());

      expect(result, const Left(failure));
      verify(
        () => local.queuePersonImageUpload(tempId: any(named: 'tempId'), payloadJson: any(named: 'payloadJson')),
      ).called(1);
    });
  });

  group('deleteImage (pure optimistic path)', () {
    test('queues a delete via the outbox and returns immediately with no remote call', () async {
      final result = await repository.deleteImage(personId: 10, imageId: 1);

      expect(result, const Right(unit));
      verify(() => local.queueDeletedImage(1, payloadJson: any(named: 'payloadJson'))).called(1);
      verifyNever(() => remote.deleteImage(any(), any()));
    });
  });

  group('setPrimary (pure optimistic path)', () {
    test('queues an update via the outbox and returns immediately with no remote call', () async {
      final result = await repository.setPrimary(personId: 10, imageId: 2);

      expect(result.isRight(), isTrue);
      verify(
        () => local.queueSetPrimary(personId: 10, id: 2, payloadJson: any(named: 'payloadJson')),
      ).called(1);
      verifyNever(() => remote.setPrimary(any(), any()));
    });
  });

  group('refreshImages (permanent full-refetch-as-delta)', () {
    test('applies the fetched snapshot', () async {
      when(() => remote.getAllMinePersonImages()).thenAnswer(
        (_) async => const Right([PersonImageProfileResponse(id: 1, personId: 10, objectKey: 'people/10/a.jpg', isPrimary: true)]),
      );

      final result = await repository.refreshImages();

      expect(result, const Right(unit));
      final captured = verify(() => local.applyPersonImagesSnapshot(captureAny())).captured;
      expect((captured.single as List<PersonImageRef>).map((i) => i.id), [1]);
    });

    test('propagates a failure unchanged', () async {
      const failure = NetworkFailure();
      when(() => remote.getAllMinePersonImages()).thenAnswer((_) async => const Left(failure));

      final result = await repository.refreshImages();

      expect(result, const Left(failure));
      verifyNever(() => local.applyPersonImagesSnapshot(any()));
    });
  });
}

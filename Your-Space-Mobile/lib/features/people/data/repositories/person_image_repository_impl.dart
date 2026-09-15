import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/person_image.dart';
import 'package:your_space_mobile/core/entities/person_image_ref.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import '../../domain/repositories/base_person_image_repository.dart';
import '../datasources/base_person_image_data_source.dart';
import '../datasources/person_image_local_data_source_impl.dart';

@LazySingleton(as: PersonImageRepository)
class PersonImageRepositoryImpl implements PersonImageRepository {
  final BasePersonImageDataSource _remote;
  final PersonImageLocalDataSourceImpl _local;
  final SyncService _syncService;

  PersonImageRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
    this._syncService,
  );

  @override
  Future<Either<Failure, List<PersonImage>>> getImages(int personId) async {
    final result = await _remote.getImages(personId);
    return result.fold(Left.new, (list) => Right(list.map((r) => r.toEntity()).toList()));
  }

  int _newTempId() => -DateTime.now().microsecondsSinceEpoch;

  /// Queues the upload via the outbox (design doc §9) and immediately asks
  /// `SyncService` to replay it, so the caller gets back a real
  /// server-confirmed image (with a resolvable id/url) rather than nothing
  /// — the wizard's own submit flow needs the real id synchronously to
  /// thread into a same-session `setPrimary` call. Mirrors
  /// `CityRepositoryImpl.createCityAndSync`: the queued row is NOT rolled
  /// back when the immediate replay fails (offline/server error) — it stays
  /// queued for background retry, but this call reports the failure so the
  /// wizard can surface it instead of silently proceeding.
  @override
  Future<Either<Failure, PersonImage>> uploadImage({required int personId, required File file}) async {
    final payloadJson = jsonEncode({
      'personId': personId,
      'localFilePath': file.path,
      'isPrimary': false,
    });
    final rowId = await _local.queuePersonImageUpload(tempId: _newTempId(), payloadJson: payloadJson);
    final result = await _syncService.replayRow(rowId);
    return result.fold(Left.new, (payload) => Right(payload as PersonImage));
  }

  @override
  Future<Either<Failure, Unit>> deleteImage({required int personId, required int imageId}) async {
    await _local.queueDeletedImage(imageId, payloadJson: jsonEncode({'personId': personId}));
    return const Right(unit);
  }

  @override
  Future<Either<Failure, PersonImage>> setPrimary({required int personId, required int imageId}) async {
    await _local.queueSetPrimary(
      personId: personId,
      id: imageId,
      payloadJson: jsonEncode({'personId': personId}),
    );
    // No presigned url available until the server confirms — the wizard's
    // own call site doesn't read this success value's fields, only whether
    // it succeeded (see `PersonWizardCubit._syncPhotos`), so an empty url
    // placeholder is safe here; a real one lands via the next
    // getImages()/Tier 3 refresh.
    return Right(PersonImage(id: imageId, url: '', isPrimary: true));
  }

  @override
  Future<Either<Failure, Unit>> refreshImages() async {
    final result = await _remote.getAllMinePersonImages();
    return result.fold(
      Left.new,
      (responses) async {
        await _local.applyPersonImagesSnapshot(responses
            .map((r) => PersonImageRef(id: r.id, personId: r.personId, objectKey: r.objectKey, isPrimary: r.isPrimary))
            .toList());
        return const Right(unit);
      },
    );
  }
}

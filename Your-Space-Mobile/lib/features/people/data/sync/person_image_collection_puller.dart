import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_person_image_repository.dart';

/// `SyncService`'s collection: 'personImages' strategy — a thin wrapper
/// over `PersonImageRepository.refreshImages()`, which is PersonImage's
/// **permanent** full-refetch-as-delta pull (row 9 cross-cutting decision).
/// Mirrors `EventGuestCollectionPuller`.
@Named('personImage')
@LazySingleton(as: CollectionPuller)
class PersonImageCollectionPuller implements CollectionPuller {
  final PersonImageRepository _personImageRepository;

  PersonImageCollectionPuller(this._personImageRepository);

  @override
  String get collection => 'personImages';

  @override
  Future<Either<Failure, Unit>> pull() => _personImageRepository.refreshImages();
}

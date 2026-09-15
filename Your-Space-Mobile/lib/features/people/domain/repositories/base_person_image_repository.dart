import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/person_image.dart';
import 'package:your_space_mobile/core/network/failure.dart';

abstract class PersonImageRepository {
  /// Server-computed/live URL, stays network-only forever (a presigned URL
  /// expires within minutes/hours — design doc §8 analogue). Never cached,
  /// never routed through local drift.
  Future<Either<Failure, List<PersonImage>>> getImages(int personId);

  Future<Either<Failure, PersonImage>> uploadImage({required int personId, required File file});

  Future<Either<Failure, Unit>> deleteImage({required int personId, required int imageId});

  Future<Either<Failure, PersonImage>> setPrimary({required int personId, required int imageId});

  /// Tier 3 background pull (design doc §6) — **permanent**
  /// full-refetch-as-delta, not an interim stage (row 9 cross-cutting
  /// decision: PersonImage is hard-delete-only). Called by
  /// `PersonImageCollectionPuller` from `SyncService`'s background pull
  /// cadence, never awaited from a cubit or screen.
  Future<Either<Failure, Unit>> refreshImages();
}

import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import '../models/person_image_profile_response.dart';
import '../models/person_image_response.dart';

/// Contract for `PersonImageRepositoryImpl`'s remote dependency, mirrors
/// `BasePersonRelationshipDataSource`. PersonImage's first abstract
/// data-source seam. `getImages` stays network-only forever (design doc §8
/// analogue — a presigned URL can't be cached as if stable), never routed
/// through local drift.
abstract class BasePersonImageDataSource {
  Future<Either<Failure, List<PersonImageResponse>>> getImages(int personId);

  /// Flat "all mine" pull (row 9.15/9.16) — person-agnostic bookkeeping-only
  /// shape (object keys, not presigned URLs). Feeds Tier 1's bulk local
  /// population and (row 9.18) the permanent full-refetch pull.
  Future<Either<Failure, List<PersonImageProfileResponse>>> getAllMinePersonImages();

  Future<Either<Failure, PersonImageResponse>> uploadImage(int personId, File file);

  Future<Either<Failure, Unit>> deleteImage(int personId, int imageId);

  Future<Either<Failure, PersonImageResponse>> setPrimary(int personId, int imageId);
}

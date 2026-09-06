import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/person_image.dart';
import 'package:your_space_mobile/core/network/failure.dart';

abstract class PersonImageRepository {
  Future<Either<Failure, List<PersonImage>>> getImages(int personId);
  Future<Either<Failure, PersonImage>> uploadImage({required int personId, required File file});
  Future<Either<Failure, Unit>> deleteImage({required int personId, required int imageId});
  Future<Either<Failure, PersonImage>> setPrimary({required int personId, required int imageId});
}

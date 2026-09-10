import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/person_image.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/repositories/base_person_image_repository.dart';
import '../datasources/person_image_remote_data_source_impl.dart';

@LazySingleton(as: PersonImageRepository)
class PersonImageRepositoryImpl implements PersonImageRepository {
  final PersonImageRemoteDataSourceImpl _remote;

  PersonImageRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<PersonImage>>> getImages(int personId) async {
    final result = await _remote.getImages(personId);
    return result.fold(Left.new, (list) => Right(list.map((r) => r.toEntity()).toList()));
  }

  @override
  Future<Either<Failure, PersonImage>> uploadImage({required int personId, required File file}) async {
    final result = await _remote.uploadImage(personId, file);
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, Unit>> deleteImage({required int personId, required int imageId}) =>
      _remote.deleteImage(personId, imageId);

  @override
  Future<Either<Failure, PersonImage>> setPrimary({required int personId, required int imageId}) async {
    final result = await _remote.setPrimary(personId, imageId);
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }
}

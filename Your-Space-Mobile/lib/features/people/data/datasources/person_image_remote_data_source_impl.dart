import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/constants/api_constants.dart';
import 'package:your_space_mobile/core/network/api_envelope.dart';
import 'package:your_space_mobile/core/network/api_manager.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'base_person_image_data_source.dart';
import '../models/person_image_profile_response.dart';
import '../models/person_image_response.dart';

@Named('remote')
@LazySingleton(as: BasePersonImageDataSource)
class PersonImageRemoteDataSourceImpl implements BasePersonImageDataSource {
  final ApiManager _api;

  PersonImageRemoteDataSourceImpl(this._api);

  String _basePath(int personId) => '${ApiConstants.persons}/$personId/${ApiConstants.personImagesSegment}';

  @override
  Future<Either<Failure, List<PersonImageProfileResponse>>> getAllMinePersonImages() =>
      _api.get<List<PersonImageProfileResponse>>(
        path: ApiConstants.personImages,
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => (inner as List<dynamic>)
              .map((item) => PersonImageProfileResponse.fromJson(item as Map<String, dynamic>))
              .toList(),
        ),
      );

  @override
  Future<Either<Failure, List<PersonImageResponse>>> getImages(int personId) => _api.get<List<PersonImageResponse>>(
        path: _basePath(personId),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) =>
              (inner as List<dynamic>).map((e) => PersonImageResponse.fromJson(e as Map<String, dynamic>)).toList(),
        ),
      );

  @override
  Future<Either<Failure, PersonImageResponse>> uploadImage(int personId, File file) async {
    final formData = FormData.fromMap({
      'File': await MultipartFile.fromFile(file.path),
    });
    return _api.post<PersonImageResponse>(
      path: _basePath(personId),
      data: formData,
      fromJson: (json) => unwrapServiceResult(
        json,
        (inner) => PersonImageResponse.fromJson(inner as Map<String, dynamic>),
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> deleteImage(int personId, int imageId) => _api.delete<Unit>(
        path: '${_basePath(personId)}/$imageId',
        fromJson: (_) => unit,
      );

  @override
  Future<Either<Failure, PersonImageResponse>> setPrimary(int personId, int imageId) =>
      _api.post<PersonImageResponse>(
        path: '${_basePath(personId)}/$imageId/set-primary',
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PersonImageResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );
}

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/constants/api_constants.dart';
import 'package:your_space_mobile/core/network/api_envelope.dart';
import 'package:your_space_mobile/core/network/api_manager.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'base_person_relationship_data_source.dart';
import '../models/create_person_relationship_request.dart';
import '../models/create_person_relationship_response.dart';
import '../models/person_details_response.dart';

@Named('remote')
@LazySingleton(as: BasePersonRelationshipDataSource)
class PersonRelationshipRemoteDataSourceImpl implements BasePersonRelationshipDataSource {
  final ApiManager _api;

  PersonRelationshipRemoteDataSourceImpl(this._api);

  String _basePath(int personId) =>
      '${ApiConstants.persons}/$personId/${ApiConstants.personRelationshipsSegment}';

  @override
  Future<Either<Failure, List<PersonRelationshipResponse>>> getAllMinePersonRelationships() =>
      _api.get<List<PersonRelationshipResponse>>(
        path: ApiConstants.personRelationships,
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => (inner as List<dynamic>)
              .map((e) => PersonRelationshipResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );

  @override
  Future<Either<Failure, List<PersonRelationshipResponse>>> getRelationships(int personId) =>
      _api.get<List<PersonRelationshipResponse>>(
        path: _basePath(personId),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => (inner as List<dynamic>)
              .map((e) => PersonRelationshipResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );

  @override
  Future<Either<Failure, CreatePersonRelationshipResponse>> createRelationship(
    int personId,
    CreatePersonRelationshipRequest request,
  ) =>
      _api.post<CreatePersonRelationshipResponse>(
        path: _basePath(personId),
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => CreatePersonRelationshipResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  @override
  Future<Either<Failure, Unit>> deleteRelationship(int personId, int relationshipId) => _api.delete<Unit>(
        path: '${_basePath(personId)}/$relationshipId',
        fromJson: (_) => unit,
      );
}

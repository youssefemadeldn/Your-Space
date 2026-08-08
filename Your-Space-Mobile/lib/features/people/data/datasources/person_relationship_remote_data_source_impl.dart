import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/constants/api_constants.dart';
import 'package:your_space_mobile/core/network/api_envelope.dart';
import 'package:your_space_mobile/core/network/api_manager.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../models/create_person_relationship_request.dart';
import '../models/person_details_response.dart';

@lazySingleton
class PersonRelationshipRemoteDataSourceImpl {
  final ApiManager _api;

  PersonRelationshipRemoteDataSourceImpl(this._api);

  String _basePath(int personId) =>
      '${ApiConstants.persons}/$personId/${ApiConstants.personRelationshipsSegment}';

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

  Future<Either<Failure, PersonRelationshipResponse>> createRelationship(
    int personId,
    CreatePersonRelationshipRequest request,
  ) =>
      _api.post<PersonRelationshipResponse>(
        path: _basePath(personId),
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PersonRelationshipResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, Unit>> deleteRelationship(int personId, int relationshipId) => _api.delete<Unit>(
        path: '${_basePath(personId)}/$relationshipId',
        fromJson: (_) => unit,
      );
}

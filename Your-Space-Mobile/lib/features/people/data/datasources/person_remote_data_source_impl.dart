import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/constants/api_constants.dart';
import 'package:your_space_mobile/core/network/api_envelope.dart';
import 'package:your_space_mobile/core/network/api_manager.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/add_occasion_history_request.dart';
import '../models/create_person_request.dart';
import '../models/person_details_response.dart';
import '../models/person_occasion_history_response.dart';
import '../models/person_response.dart';
import '../models/update_person_request.dart';

@lazySingleton
class PersonRemoteDataSourceImpl {
  final ApiManager _api;

  PersonRemoteDataSourceImpl(this._api);

  Future<Either<Failure, PaginatedResponse<PersonResponse>>> getPersons({
    int? groupId,
    String? search,
    required int pageIndex,
    required int pageSize,
  }) =>
      _api.get<PaginatedResponse<PersonResponse>>(
        path: ApiConstants.persons,
        queryParameters: {
          if (groupId != null) 'groupId': groupId,
          if (search != null) 'search': search,
          'pageIndex': pageIndex,
          'pageSize': pageSize,
        },
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PaginatedResponse.fromJson(
            inner as Map<String, dynamic>,
            (item) => PersonResponse.fromJson(item as Map<String, dynamic>),
          ),
        ),
      );

  Future<Either<Failure, PersonDetailsResponse>> getPersonById(int id) => _api.get<PersonDetailsResponse>(
        path: '${ApiConstants.persons}/$id',
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PersonDetailsResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, PersonResponse>> createPerson(CreatePersonRequest request) =>
      _api.post<PersonResponse>(
        path: ApiConstants.persons,
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PersonResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, PersonResponse>> updatePerson(UpdatePersonRequest request) =>
      _api.put<PersonResponse>(
        path: ApiConstants.persons,
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PersonResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, PersonOccasionHistoryResponse>> addOccasionHistory(
    int personId,
    AddOccasionHistoryRequest request,
  ) =>
      _api.post<PersonOccasionHistoryResponse>(
        path: '${ApiConstants.persons}/$personId/occasion-history',
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => PersonOccasionHistoryResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );
}

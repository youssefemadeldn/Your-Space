import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import '../models/add_occasion_history_request.dart';
import '../models/create_person_request.dart';
import '../models/person_details_response.dart';
import '../models/person_occasion_history_response.dart';
import '../models/person_response.dart';
import '../models/update_person_request.dart';

/// Contract for `PersonRepositoryImpl`'s remote dependency.
///
/// This mirrors the remote data source's full surface, not just reads: the
/// repository still calls `createPerson`/`updatePerson`/`addOccasionHistory`
/// directly against remote (unchanged in this row), and injectable's
/// `@LazySingleton(as: X)` registers the instance only under `X` — so every
/// method the repository needs from `_remote` has to be reachable through
/// this interface. `PersonLocalDataSourceImpl` does not implement this
/// contract; it's a separate, concrete local surface.
abstract class BasePersonDataSource {
  Future<Either<Failure, PaginatedResponse<PersonResponse>>> getPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, PersonDetailsResponse>> getPersonById(int id);

  Future<Either<Failure, PersonResponse>> createPerson(CreatePersonRequest request);

  Future<Either<Failure, PersonResponse>> updatePerson(UpdatePersonRequest request);

  Future<Either<Failure, PersonOccasionHistoryResponse>> addOccasionHistory(
    int personId,
    AddOccasionHistoryRequest request,
  );
}

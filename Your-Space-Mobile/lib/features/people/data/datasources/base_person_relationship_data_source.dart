import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import '../models/create_person_relationship_request.dart';
import '../models/create_person_relationship_response.dart';
import '../models/person_details_response.dart';

/// Contract for `PersonRelationshipRepositoryImpl`'s remote dependency,
/// mirrors `BaseEventGuestDataSource`. PersonRelationship's first abstract
/// data-source seam — the concrete `PersonRelationshipRemoteDataSourceImpl`
/// was previously injected directly.
abstract class BasePersonRelationshipDataSource {
  Future<Either<Failure, List<PersonRelationshipResponse>>> getRelationships(int personId);

  /// Flat "all mine" pull (row 9.11/9.16) — person-agnostic, feeds Tier 1's
  /// bulk local population and (row 9.14) the permanent full-refetch pull.
  Future<Either<Failure, List<PersonRelationshipResponse>>> getAllMinePersonRelationships();

  /// Row 9.13: the response carries both the forward row and the
  /// auto-derived inverse row's id/type, so the caller can reconcile the
  /// whole symmetric pair from one round trip.
  Future<Either<Failure, CreatePersonRelationshipResponse>> createRelationship(
    int personId,
    CreatePersonRelationshipRequest request,
  );

  Future<Either<Failure, Unit>> deleteRelationship(int personId, int relationshipId);
}

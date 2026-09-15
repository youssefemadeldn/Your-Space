import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/person_relationship.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';
import 'package:your_space_mobile/core/network/failure.dart';

abstract class PersonRelationshipRepository {
  Future<Either<Failure, List<PersonRelationship>>> getRelationships(int personId);

  /// Tier 1 read path (local-first, CLAUDE.md rule 7) — reads local drift
  /// only, never touches the network. No known cubit caller yet (kept as a
  /// documented primitive, mirrors other entities' own "no caller today"
  /// precedent) — `PersonWizardCubit` currently sources a person's
  /// relationships from `PersonDetails.relationships` (a different, still
  /// network-sourced read path, unchanged by this row).
  Stream<List<PersonRelationship>> watchRelationships({required int personId, required int limit});

  /// Tier 3 background pull (design doc §6) — **permanent**
  /// full-refetch-as-delta, not an interim stage (row 9 cross-cutting
  /// decision: PersonRelationship is hard-delete-only). Called by
  /// `PersonRelationshipCollectionPuller` from `SyncService`'s background
  /// pull cadence, never awaited from a cubit or screen.
  Future<Either<Failure, Unit>> refreshRelationships();

  Future<Either<Failure, PersonRelationship>> createRelationship({
    required int personId,
    required int relatedPersonId,
    required RelationType relationType,
  });

  Future<Either<Failure, Unit>> deleteRelationship({required int personId, required int relationshipId});
}

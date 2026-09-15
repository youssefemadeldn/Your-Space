import 'package:equatable/equatable.dart';

import 'relation_type.dart';

/// One row of a person's outgoing relationship list — mirrors
/// `PersonRelationshipProfileDto`. Lives in core (consumed by the people
/// feature's wizard/details and, transitively, nothing else yet).
class PersonRelationship extends Equatable {
  final int id;

  // Present on every row (row 9.11) — the nested per-person read never
  // needed it (the caller already has `personId` from context), but the
  // local-first cache does, since it holds every person's relationships in
  // one table and must filter/tombstone by id alone during a full-refetch.
  final int personId;

  final int relatedPersonId;
  final String relatedPersonName;
  final RelationType relationType;

  // The auto-derived inverse row's real id (row 9.13's "symmetric pair"
  // mechanism) — null only for a row that hasn't round-tripped through the
  // server yet (a local temp-id draft mid-sync).
  final int? inverseId;

  const PersonRelationship({
    required this.id,
    required this.personId,
    required this.relatedPersonId,
    required this.relatedPersonName,
    required this.relationType,
    this.inverseId,
  });

  @override
  List<Object?> get props => [id, personId, relatedPersonId, relatedPersonName, relationType, inverseId];
}

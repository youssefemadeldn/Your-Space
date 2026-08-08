import 'package:equatable/equatable.dart';

import 'relation_type.dart';

/// One row of a person's outgoing relationship list — mirrors
/// `PersonRelationshipProfileDto`. Lives in core (consumed by the people
/// feature's wizard/details and, transitively, nothing else yet).
class PersonRelationship extends Equatable {
  final int id;
  final int relatedPersonId;
  final String relatedPersonName;
  final RelationType relationType;

  const PersonRelationship({
    required this.id,
    required this.relatedPersonId,
    required this.relatedPersonName,
    required this.relationType,
  });

  @override
  List<Object?> get props => [id, relatedPersonId, relatedPersonName, relationType];
}

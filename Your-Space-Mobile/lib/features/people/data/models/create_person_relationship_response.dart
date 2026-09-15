import 'package:your_space_mobile/core/entities/relation_type.dart';

/// Parses `PersonRelationshipDetailsDto`'s create-response shape (row 9.13)
/// — a superset of `PersonRelationshipResponse`'s list-row shape, carrying
/// the auto-derived inverse row's own id/type alongside the forward row's.
/// The inverse row's own `personId`/`relatedPersonId`/`relatedPersonName`
/// are all already known to the caller (`relatedPersonId` and the subject
/// person's own name) — only the id/type needed sending.
class CreatePersonRelationshipResponse {
  final int id;
  final int personId;
  final int relatedPersonId;
  final String relatedPersonName;
  final RelationType relationType;
  final int inverseId;
  final RelationType inverseRelationType;

  const CreatePersonRelationshipResponse({
    required this.id,
    required this.personId,
    required this.relatedPersonId,
    required this.relatedPersonName,
    required this.relationType,
    required this.inverseId,
    required this.inverseRelationType,
  });

  factory CreatePersonRelationshipResponse.fromJson(Map<String, dynamic> json) => CreatePersonRelationshipResponse(
        id: json['id'] as int,
        personId: json['personId'] as int,
        relatedPersonId: json['relatedPersonId'] as int,
        relatedPersonName: json['relatedPersonName'] as String,
        relationType: RelationType.fromWire(json['relationType'] as String),
        inverseId: json['inverseId'] as int,
        inverseRelationType: RelationType.fromWire(json['inverseRelationType'] as String),
      );
}

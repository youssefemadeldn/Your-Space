import 'package:your_space_mobile/core/entities/relation_type.dart';

class CreatePersonRelationshipRequest {
  final int relatedPersonId;
  final RelationType relationType;

  const CreatePersonRelationshipRequest({required this.relatedPersonId, required this.relationType});

  Map<String, dynamic> toJson() => {
        'relatedPersonId': relatedPersonId,
        'relationType': relationType.toWire(),
      };
}

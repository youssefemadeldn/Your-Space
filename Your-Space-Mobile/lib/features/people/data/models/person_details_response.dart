import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/entities/person_relationship.dart' as core;
import 'package:your_space_mobile/core/entities/relation_type.dart';
import 'package:your_space_mobile/features/people/domain/entities/person_details.dart';

import 'person_occasion_history_response.dart';

class PersonDetailsResponse {
  final int id;
  final String name;
  final String? phoneNumber;
  final String? phoneNumber2;
  final Gender gender;
  final int groupId;
  final String groupName;
  final int? subGroupId;
  final String? subGroupName;
  final int governorateId;
  final String governorateName;
  final int? cityId;
  final String? cityName;
  final int? neighborhoodId;
  final String? neighborhoodName;
  final String? primaryPhotoUrl;
  final String? notes;
  final bool hasReciprocityHistory;
  final List<PersonOccasionHistoryResponse> occasionHistory;
  final List<PersonRelationshipResponse> relationships;
  final DateTime createdAt;

  const PersonDetailsResponse({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.phoneNumber2,
    required this.gender,
    required this.groupId,
    required this.groupName,
    this.subGroupId,
    this.subGroupName,
    required this.governorateId,
    required this.governorateName,
    this.cityId,
    this.cityName,
    this.neighborhoodId,
    this.neighborhoodName,
    this.primaryPhotoUrl,
    this.notes,
    required this.hasReciprocityHistory,
    required this.occasionHistory,
    required this.relationships,
    required this.createdAt,
  });

  factory PersonDetailsResponse.fromJson(Map<String, dynamic> json) => PersonDetailsResponse(
        id: json['id'] as int,
        name: json['name'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        phoneNumber2: json['phoneNumber2'] as String?,
        gender: Gender.fromWire(json['gender'] as String),
        groupId: json['groupId'] as int,
        groupName: json['groupName'] as String,
        subGroupId: json['subGroupId'] as int?,
        subGroupName: json['subGroupName'] as String?,
        governorateId: json['governorateId'] as int,
        governorateName: json['governorateName'] as String,
        cityId: json['cityId'] as int?,
        cityName: json['cityName'] as String?,
        neighborhoodId: json['neighborhoodId'] as int?,
        neighborhoodName: json['neighborhoodName'] as String?,
        primaryPhotoUrl: json['primaryPhotoUrl'] as String?,
        notes: json['notes'] as String?,
        hasReciprocityHistory: json['hasReciprocityHistory'] as bool,
        occasionHistory: (json['occasionHistory'] as List<dynamic>? ?? const [])
            .map((e) => PersonOccasionHistoryResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        relationships: (json['relationships'] as List<dynamic>? ?? const [])
            .map((e) => PersonRelationshipResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  PersonDetails toEntity() => PersonDetails(
        person: Person(
          id: id,
          name: name,
          phoneNumber: phoneNumber,
          phoneNumber2: phoneNumber2,
          gender: gender,
          groupId: groupId,
          groupName: groupName,
          subGroupId: subGroupId,
          subGroupName: subGroupName,
          governorateId: governorateId,
          governorateName: governorateName,
          cityId: cityId,
          cityName: cityName,
          neighborhoodId: neighborhoodId,
          neighborhoodName: neighborhoodName,
          primaryPhotoUrl: primaryPhotoUrl,
          notes: notes,
          hasReciprocityHistory: hasReciprocityHistory,
        ),
        occasionHistory: occasionHistory.map((e) => e.toEntity()).toList(),
        relationships: relationships.map((e) => e.toEntity()).toList(),
        createdAt: createdAt,
      );
}

/// `PersonRelationshipProfileDto` — nested inside `PersonDetailsDto.relationships`.
class PersonRelationshipResponse {
  final int id;
  final int relatedPersonId;
  final String relatedPersonName;
  final RelationType relationType;

  const PersonRelationshipResponse({
    required this.id,
    required this.relatedPersonId,
    required this.relatedPersonName,
    required this.relationType,
  });

  factory PersonRelationshipResponse.fromJson(Map<String, dynamic> json) => PersonRelationshipResponse(
        id: json['id'] as int,
        relatedPersonId: json['relatedPersonId'] as int,
        relatedPersonName: json['relatedPersonName'] as String,
        relationType: RelationType.fromWire(json['relationType'] as String),
      );

  core.PersonRelationship toEntity() => core.PersonRelationship(
        id: id,
        relatedPersonId: relatedPersonId,
        relatedPersonName: relatedPersonName,
        relationType: relationType,
      );
}

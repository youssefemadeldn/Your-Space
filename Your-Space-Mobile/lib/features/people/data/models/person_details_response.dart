import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';
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
  final String? notes;
  final bool hasReciprocityHistory;
  final List<PersonOccasionHistoryResponse> occasionHistory;
  final DateTime createdAt;

  const PersonDetailsResponse({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.phoneNumber2,
    required this.gender,
    required this.groupId,
    required this.groupName,
    this.notes,
    required this.hasReciprocityHistory,
    required this.occasionHistory,
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
        notes: json['notes'] as String?,
        hasReciprocityHistory: json['hasReciprocityHistory'] as bool,
        occasionHistory: (json['occasionHistory'] as List<dynamic>? ?? const [])
            .map((e) => PersonOccasionHistoryResponse.fromJson(e as Map<String, dynamic>))
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
          notes: notes,
          hasReciprocityHistory: hasReciprocityHistory,
        ),
        occasionHistory: occasionHistory.map((e) => e.toEntity()).toList(),
        createdAt: createdAt,
      );
}

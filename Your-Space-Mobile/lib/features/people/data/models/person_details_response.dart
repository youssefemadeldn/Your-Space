import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/features/people/domain/entities/person_details.dart';

import 'person_occasion_history_response.dart';

class PersonDetailsResponse {
  final int id;
  final String name;
  final String? phoneNumber;
  final int groupId;
  final String groupName;
  final bool hasReciprocityHistory;
  final List<PersonOccasionHistoryResponse> occasionHistory;

  const PersonDetailsResponse({
    required this.id,
    required this.name,
    this.phoneNumber,
    required this.groupId,
    required this.groupName,
    required this.hasReciprocityHistory,
    required this.occasionHistory,
  });

  factory PersonDetailsResponse.fromJson(Map<String, dynamic> json) => PersonDetailsResponse(
        id: json['id'] as int,
        name: json['name'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        groupId: json['groupId'] as int,
        groupName: json['groupName'] as String,
        hasReciprocityHistory: json['hasReciprocityHistory'] as bool,
        occasionHistory: (json['occasionHistory'] as List<dynamic>? ?? const [])
            .map((e) => PersonOccasionHistoryResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  PersonDetails toEntity() => PersonDetails(
        person: Person(
          id: id,
          name: name,
          phoneNumber: phoneNumber,
          groupId: groupId,
          groupName: groupName,
          hasReciprocityHistory: hasReciprocityHistory,
        ),
        occasionHistory: occasionHistory.map((e) => e.toEntity()).toList(),
      );
}

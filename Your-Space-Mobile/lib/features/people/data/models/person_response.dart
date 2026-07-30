import 'package:your_space_mobile/core/entities/person.dart';

/// Parses `PersonProfileDto`'s fields. Also reused for create/update
/// responses (`PersonDetailsDto`, a superset) — the extra `occasionHistory`/
/// `createdAt` keys are simply ignored since this only reads the keys below.
class PersonResponse {
  final int id;
  final String name;
  final String? phoneNumber;
  final int groupId;
  final String groupName;
  final bool hasReciprocityHistory;

  const PersonResponse({
    required this.id,
    required this.name,
    this.phoneNumber,
    required this.groupId,
    required this.groupName,
    required this.hasReciprocityHistory,
  });

  factory PersonResponse.fromJson(Map<String, dynamic> json) => PersonResponse(
        id: json['id'] as int,
        name: json['name'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        groupId: json['groupId'] as int,
        groupName: json['groupName'] as String,
        hasReciprocityHistory: json['hasReciprocityHistory'] as bool,
      );

  Person toEntity() => Person(
        id: id,
        name: name,
        phoneNumber: phoneNumber,
        groupId: groupId,
        groupName: groupName,
        hasReciprocityHistory: hasReciprocityHistory,
      );
}

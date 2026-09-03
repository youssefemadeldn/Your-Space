import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';

/// Parses `PersonProfileDto`'s fields. Also reused for create/update
/// responses (`PersonDetailsDto`, a superset) — the extra `occasionHistory`/
/// `createdAt` keys are simply ignored since this only reads the keys below.
class PersonResponse {
  final int id;
  final String name;
  final String? phoneNumber;
  final String? phoneNumber2;
  final Gender gender;
  final int groupId;
  final String groupName;
  final String? notes;
  final bool hasReciprocityHistory;

  const PersonResponse({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.phoneNumber2,
    required this.gender,
    required this.groupId,
    required this.groupName,
    this.notes,
    required this.hasReciprocityHistory,
  });

  factory PersonResponse.fromJson(Map<String, dynamic> json) => PersonResponse(
        id: json['id'] as int,
        name: json['name'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        phoneNumber2: json['phoneNumber2'] as String?,
        gender: Gender.fromWire(json['gender'] as String),
        groupId: json['groupId'] as int,
        groupName: json['groupName'] as String,
        notes: json['notes'] as String?,
        hasReciprocityHistory: json['hasReciprocityHistory'] as bool,
      );

  Person toEntity() => Person(
        id: id,
        name: name,
        phoneNumber: phoneNumber,
        phoneNumber2: phoneNumber2,
        gender: gender,
        groupId: groupId,
        groupName: groupName,
        notes: notes,
        hasReciprocityHistory: hasReciprocityHistory,
      );
}

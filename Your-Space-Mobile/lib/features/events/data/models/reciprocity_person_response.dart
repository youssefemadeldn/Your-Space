import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';

/// `GET .../reciprocity-suggestions` returns the exact same `PersonProfileDto`
/// shape as the People list endpoint (per the backend brief), so this mirrors
/// `people/data/models/person_response.dart` field-for-field. Deliberately
/// duplicated rather than imported across the feature boundary — this
/// project's rule is Feature → Core only, never Feature → Feature, even at
/// the data layer.
class ReciprocityPersonResponse {
  final int id;
  final String name;
  final String? phoneNumber;
  final String? phoneNumber2;
  final Gender gender;
  final int groupId;
  final String groupName;
  final String? notes;
  final bool hasReciprocityHistory;

  const ReciprocityPersonResponse({
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

  factory ReciprocityPersonResponse.fromJson(Map<String, dynamic> json) => ReciprocityPersonResponse(
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

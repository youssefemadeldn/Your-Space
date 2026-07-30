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
  final int groupId;
  final String groupName;
  final bool hasReciprocityHistory;

  const ReciprocityPersonResponse({
    required this.id,
    required this.name,
    this.phoneNumber,
    required this.groupId,
    required this.groupName,
    required this.hasReciprocityHistory,
  });

  factory ReciprocityPersonResponse.fromJson(Map<String, dynamic> json) => ReciprocityPersonResponse(
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

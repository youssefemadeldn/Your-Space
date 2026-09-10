import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';

/// Parses `PersonProfileDto`'s fields. Also reused for create/update
/// responses (`PersonDetailsDto`, a superset) — the extra `occasionHistory`/
/// `relationships`/`createdAt` keys are simply ignored since this only reads
/// the keys below.
class PersonResponse {
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

  const PersonResponse({
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
  });

  factory PersonResponse.fromJson(Map<String, dynamic> json) => PersonResponse(
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
      );

  Person toEntity() => Person(
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
      );
}

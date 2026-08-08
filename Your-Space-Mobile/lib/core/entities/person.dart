import 'package:equatable/equatable.dart';

import 'gender.dart';

/// Shared across the people and events features (list rows, filter dropdowns,
/// add-guests picker, reciprocity suggestions) — lives in core so the
/// dependency direction stays Feature → Core, never Feature → Feature.
/// Mirrors `PersonProfileDto` exactly.
class Person extends Equatable {
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

  const Person({
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
    this.hasReciprocityHistory = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phoneNumber,
        phoneNumber2,
        gender,
        groupId,
        groupName,
        subGroupId,
        subGroupName,
        governorateId,
        governorateName,
        cityId,
        cityName,
        neighborhoodId,
        neighborhoodName,
        primaryPhotoUrl,
        notes,
        hasReciprocityHistory,
      ];
}

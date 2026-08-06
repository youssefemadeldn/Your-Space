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
        notes,
        hasReciprocityHistory,
      ];
}

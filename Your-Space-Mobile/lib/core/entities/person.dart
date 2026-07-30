import 'package:equatable/equatable.dart';

/// Shared across the people and events features (list rows, filter dropdowns,
/// add-guests picker, reciprocity suggestions) — lives in core so the
/// dependency direction stays Feature → Core, never Feature → Feature.
/// Mirrors `PersonProfileDto` exactly.
class Person extends Equatable {
  final int id;
  final String name;
  final String? phoneNumber;
  final int groupId;
  final String groupName;
  final bool hasReciprocityHistory;

  const Person({
    required this.id,
    required this.name,
    this.phoneNumber,
    required this.groupId,
    required this.groupName,
    this.hasReciprocityHistory = false,
  });

  @override
  List<Object?> get props => [id, name, phoneNumber, groupId, groupName, hasReciprocityHistory];
}

import 'package:equatable/equatable.dart';

class Person extends Equatable {
  final int id;
  final String name;
  final String? phoneNumber;
  final int groupId;
  final String groupName;
  final bool hasReciprocityHistory;
  final DateTime createdAt;

  const Person({
    required this.id,
    required this.name,
    this.phoneNumber,
    required this.groupId,
    required this.groupName,
    this.hasReciprocityHistory = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phoneNumber,
        groupId,
        groupName,
        hasReciprocityHistory,
        createdAt,
      ];
}

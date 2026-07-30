import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/invite_method.dart';

class PersonOccasionHistoryEntry extends Equatable {
  final int id;
  final int personId;
  final bool invitedMe;
  final InviteMethod? inviteMethod;
  final String? occasionName;
  final DateTime? occasionDate;
  final String? notes;
  final DateTime createdAt;

  const PersonOccasionHistoryEntry({
    required this.id,
    required this.personId,
    required this.invitedMe,
    this.inviteMethod,
    this.occasionName,
    this.occasionDate,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        personId,
        invitedMe,
        inviteMethod,
        occasionName,
        occasionDate,
        notes,
        createdAt,
      ];
}

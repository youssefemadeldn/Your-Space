import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/features/people/domain/entities/person_occasion_history_entry.dart';

class PersonOccasionHistoryResponse {
  final int id;
  final int personId;
  final bool invitedMe;
  final InviteMethod? inviteMethod;
  final String? occasionName;
  final DateTime? occasionDate;
  final String? notes;
  final DateTime createdAt;

  const PersonOccasionHistoryResponse({
    required this.id,
    required this.personId,
    required this.invitedMe,
    this.inviteMethod,
    this.occasionName,
    this.occasionDate,
    this.notes,
    required this.createdAt,
  });

  factory PersonOccasionHistoryResponse.fromJson(Map<String, dynamic> json) =>
      PersonOccasionHistoryResponse(
        id: json['id'] as int,
        personId: json['personId'] as int,
        invitedMe: json['invitedMe'] as bool,
        inviteMethod:
            json['inviteMethod'] == null ? null : InviteMethod.fromWire(json['inviteMethod'] as String),
        occasionName: json['occasionName'] as String?,
        occasionDate:
            json['occasionDate'] == null ? null : DateTime.parse(json['occasionDate'] as String),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  PersonOccasionHistoryEntry toEntity() => PersonOccasionHistoryEntry(
        id: id,
        personId: personId,
        invitedMe: invitedMe,
        inviteMethod: inviteMethod,
        occasionName: occasionName,
        occasionDate: occasionDate,
        notes: notes,
        createdAt: createdAt,
      );
}

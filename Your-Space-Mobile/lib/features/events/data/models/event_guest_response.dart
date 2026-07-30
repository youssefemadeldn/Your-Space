import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';

/// Parses `EventGuestProfileDto`'s fields (list/mutation responses) — the
/// route already implies `eventId`, so unlike `EventGuestDetailsDto` neither
/// this DTO nor this response model carries it; callers supply it explicitly
/// to [toEntity] from the request context instead.
class EventGuestResponse {
  final int id;
  final int personId;
  final String personName;
  final String? personPhoneNumber;
  final int groupId;
  final String groupName;
  final EventGuestStatus status;
  final InviteMethod? inviteMethod;
  final DateTime? invitedAt;

  const EventGuestResponse({
    required this.id,
    required this.personId,
    required this.personName,
    this.personPhoneNumber,
    required this.groupId,
    required this.groupName,
    required this.status,
    this.inviteMethod,
    this.invitedAt,
  });

  factory EventGuestResponse.fromJson(Map<String, dynamic> json) => EventGuestResponse(
        id: json['id'] as int,
        personId: json['personId'] as int,
        personName: json['personName'] as String,
        personPhoneNumber: json['personPhoneNumber'] as String?,
        groupId: json['groupId'] as int,
        groupName: json['groupName'] as String,
        status: EventGuestStatus.fromWire(json['status'] as String),
        inviteMethod:
            json['inviteMethod'] == null ? null : InviteMethod.fromWire(json['inviteMethod'] as String),
        invitedAt: json['invitedAt'] == null ? null : DateTime.parse(json['invitedAt'] as String),
      );

  EventGuest toEntity(int eventId) => EventGuest(
        id: id,
        eventId: eventId,
        personId: personId,
        personName: personName,
        personPhoneNumber: personPhoneNumber,
        groupId: groupId,
        groupName: groupName,
        status: status,
        inviteMethod: inviteMethod,
        invitedAt: invitedAt,
      );
}

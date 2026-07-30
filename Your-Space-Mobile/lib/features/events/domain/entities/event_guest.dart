import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/invite_method.dart';

import 'event_guest_status.dart';

class EventGuest extends Equatable {
  final int id;
  final int eventId;
  final int personId;
  final String personName;
  final String? personPhoneNumber;
  final int groupId;
  final String groupName;
  final EventGuestStatus status;
  final InviteMethod? inviteMethod;
  final DateTime? invitedAt;

  const EventGuest({
    required this.id,
    required this.eventId,
    required this.personId,
    required this.personName,
    this.personPhoneNumber,
    required this.groupId,
    required this.groupName,
    this.status = EventGuestStatus.notInvited,
    this.inviteMethod,
    this.invitedAt,
  });

  @override
  List<Object?> get props => [
        id,
        eventId,
        personId,
        personName,
        personPhoneNumber,
        groupId,
        groupName,
        status,
        inviteMethod,
        invitedAt,
      ];
}

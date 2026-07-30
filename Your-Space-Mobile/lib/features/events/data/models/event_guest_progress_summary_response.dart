import 'package:your_space_mobile/features/events/domain/entities/event_guest_progress_summary.dart';

import 'group_guest_progress_response.dart';

class EventGuestProgressSummaryResponse {
  final int eventId;
  final int totalGuestCount;
  final int notInvitedCount;
  final int invitedCount;
  final int skippedCount;
  final List<GroupGuestProgressResponse> groups;

  const EventGuestProgressSummaryResponse({
    required this.eventId,
    required this.totalGuestCount,
    required this.notInvitedCount,
    required this.invitedCount,
    required this.skippedCount,
    required this.groups,
  });

  factory EventGuestProgressSummaryResponse.fromJson(Map<String, dynamic> json) =>
      EventGuestProgressSummaryResponse(
        eventId: json['eventId'] as int,
        totalGuestCount: json['totalGuestCount'] as int,
        notInvitedCount: json['notInvitedCount'] as int,
        invitedCount: json['invitedCount'] as int,
        skippedCount: json['skippedCount'] as int,
        groups: (json['groups'] as List<dynamic>? ?? const [])
            .map((e) => GroupGuestProgressResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  EventGuestProgressSummary toEntity() => EventGuestProgressSummary(
        eventId: eventId,
        totalGuestCount: totalGuestCount,
        notInvitedCount: notInvitedCount,
        invitedCount: invitedCount,
        skippedCount: skippedCount,
        groups: groups.map((g) => g.toEntity()).toList(),
      );
}

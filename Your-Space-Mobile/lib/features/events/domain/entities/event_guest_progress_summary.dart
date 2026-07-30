import 'package:equatable/equatable.dart';

import 'group_guest_progress.dart';

class EventGuestProgressSummary extends Equatable {
  final int eventId;
  final int totalGuestCount;
  final int notInvitedCount;
  final int invitedCount;
  final int skippedCount;
  final List<GroupGuestProgress> groups;

  const EventGuestProgressSummary({
    required this.eventId,
    required this.totalGuestCount,
    required this.notInvitedCount,
    required this.invitedCount,
    required this.skippedCount,
    required this.groups,
  });

  @override
  List<Object?> get props =>
      [eventId, totalGuestCount, notInvitedCount, invitedCount, skippedCount, groups];
}

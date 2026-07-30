import 'package:your_space_mobile/features/events/domain/entities/group_guest_progress.dart';

class GroupGuestProgressResponse {
  final int groupId;
  final String groupName;
  final int totalPersonsInGroup;
  final int guestsAddedCount;
  final int notInvitedCount;
  final int invitedCount;
  final int skippedCount;

  const GroupGuestProgressResponse({
    required this.groupId,
    required this.groupName,
    required this.totalPersonsInGroup,
    required this.guestsAddedCount,
    required this.notInvitedCount,
    required this.invitedCount,
    required this.skippedCount,
  });

  factory GroupGuestProgressResponse.fromJson(Map<String, dynamic> json) => GroupGuestProgressResponse(
        groupId: json['groupId'] as int,
        groupName: json['groupName'] as String,
        totalPersonsInGroup: json['totalPersonsInGroup'] as int,
        guestsAddedCount: json['guestsAddedCount'] as int,
        notInvitedCount: json['notInvitedCount'] as int,
        invitedCount: json['invitedCount'] as int,
        skippedCount: json['skippedCount'] as int,
      );

  GroupGuestProgress toEntity() => GroupGuestProgress(
        groupId: groupId,
        groupName: groupName,
        totalPersonsInGroup: totalPersonsInGroup,
        guestsAddedCount: guestsAddedCount,
        notInvitedCount: notInvitedCount,
        invitedCount: invitedCount,
        skippedCount: skippedCount,
      );
}

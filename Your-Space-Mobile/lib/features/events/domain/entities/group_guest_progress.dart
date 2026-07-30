import 'package:equatable/equatable.dart';

/// Mirrors `GroupGuestProgressDto` — always includes zero-guest groups, so a
/// group with no guests added yet still renders a row.
class GroupGuestProgress extends Equatable {
  final int groupId;
  final String groupName;
  final int totalPersonsInGroup;
  final int guestsAddedCount;
  final int notInvitedCount;
  final int invitedCount;
  final int skippedCount;

  const GroupGuestProgress({
    required this.groupId,
    required this.groupName,
    required this.totalPersonsInGroup,
    required this.guestsAddedCount,
    required this.notInvitedCount,
    required this.invitedCount,
    required this.skippedCount,
  });

  @override
  List<Object?> get props => [
        groupId,
        groupName,
        totalPersonsInGroup,
        guestsAddedCount,
        notInvitedCount,
        invitedCount,
        skippedCount,
      ];
}

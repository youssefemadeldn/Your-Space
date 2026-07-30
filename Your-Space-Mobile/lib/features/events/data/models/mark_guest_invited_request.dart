import 'package:your_space_mobile/core/entities/invite_method.dart';

class MarkGuestInvitedRequest {
  final InviteMethod inviteMethod;

  const MarkGuestInvitedRequest({required this.inviteMethod});

  Map<String, dynamic> toJson() => {'inviteMethod': inviteMethod.toWire()};
}

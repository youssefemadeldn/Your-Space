import 'package:your_space_mobile/core/entities/invite_method.dart';

class AddOccasionHistoryRequest {
  final bool invitedMe;
  final InviteMethod? inviteMethod;
  final String? occasionName;
  final DateTime? occasionDate;
  final String? notes;

  const AddOccasionHistoryRequest({
    required this.invitedMe,
    this.inviteMethod,
    this.occasionName,
    this.occasionDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'invitedMe': invitedMe,
        if (inviteMethod != null) 'inviteMethod': inviteMethod!.toWire(),
        if (occasionName != null) 'occasionName': occasionName,
        if (occasionDate != null) 'occasionDate': occasionDate!.toIso8601String(),
        if (notes != null) 'notes': notes,
      };
}

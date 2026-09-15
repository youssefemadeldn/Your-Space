import 'package:your_space_mobile/core/entities/subgroup.dart';

/// Reused for both the paginated list (`SubGroupProfileDto`, has
/// `personCount`) and create/update responses (`SubGroupDetailsDto`, no
/// `personCount`) — defaults to 0 when absent, correct for a just-created row.
class SubGroupResponse {
  final int id;
  final int groupId;
  final String name;
  final String? nameAr;
  final int personCount;
  final DateTime? updatedAt;

  const SubGroupResponse({
    required this.id,
    required this.groupId,
    required this.name,
    this.nameAr,
    this.personCount = 0,
    this.updatedAt,
  });

  factory SubGroupResponse.fromJson(Map<String, dynamic> json) => SubGroupResponse(
        id: json['id'] as int,
        groupId: json['groupId'] as int,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String?,
        personCount: json['personCount'] as int? ?? 0,
        updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
      );

  SubGroup toEntity() => SubGroup(
        id: id,
        groupId: groupId,
        name: name,
        nameAr: nameAr,
        personCount: personCount,
        updatedAt: updatedAt,
      );
}

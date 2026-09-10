import 'package:your_space_mobile/core/entities/governorate.dart';

/// Reused for both the paginated list (`GovernorateProfileDto`, has
/// `isLocked`+`personCount`) and the create response (`GovernorateDetailsDto`,
/// has `isLocked` but no `personCount`) — `personCount` defaults to 0 when
/// absent, correct for a just-created row. Governorate is create-only from
/// mobile — no update/delete request models exist (see B7's asymmetry note).
class GovernorateResponse {
  final int id;
  final String name;
  final String? nameAr;
  final bool isLocked;
  final int personCount;

  const GovernorateResponse({
    required this.id,
    required this.name,
    this.nameAr,
    required this.isLocked,
    this.personCount = 0,
  });

  factory GovernorateResponse.fromJson(Map<String, dynamic> json) => GovernorateResponse(
        id: json['id'] as int,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String?,
        isLocked: json['isLocked'] as bool,
        personCount: json['personCount'] as int? ?? 0,
      );

  Governorate toEntity() =>
      Governorate(id: id, name: name, nameAr: nameAr, isLocked: isLocked, personCount: personCount);
}

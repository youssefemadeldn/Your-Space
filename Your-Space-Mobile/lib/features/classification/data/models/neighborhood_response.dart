import 'package:your_space_mobile/core/entities/neighborhood.dart';

/// Reused for both the paginated list (`NeighborhoodProfileDto`, has
/// `personCount`) and create/update responses (`NeighborhoodDetailsDto`, no
/// `personCount`) — defaults to 0 when absent, correct for a just-created row.
class NeighborhoodResponse {
  final int id;
  final int cityId;
  final String name;
  final String? nameAr;
  final int personCount;

  const NeighborhoodResponse({
    required this.id,
    required this.cityId,
    required this.name,
    this.nameAr,
    this.personCount = 0,
  });

  factory NeighborhoodResponse.fromJson(Map<String, dynamic> json) => NeighborhoodResponse(
        id: json['id'] as int,
        cityId: json['cityId'] as int,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String?,
        personCount: json['personCount'] as int? ?? 0,
      );

  Neighborhood toEntity() =>
      Neighborhood(id: id, cityId: cityId, name: name, nameAr: nameAr, personCount: personCount);
}

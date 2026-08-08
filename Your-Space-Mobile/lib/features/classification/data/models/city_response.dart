import 'package:your_space_mobile/core/entities/city.dart';

/// Reused for both the paginated list (`CityProfileDto`, has counts) and
/// create/update responses (`CityDetailsDto`, no counts) — counts default to
/// 0 when absent, correct for a just-created row.
class CityResponse {
  final int id;
  final int governorateId;
  final String name;
  final String? nameAr;
  final int neighborhoodCount;
  final int personCount;

  const CityResponse({
    required this.id,
    required this.governorateId,
    required this.name,
    this.nameAr,
    this.neighborhoodCount = 0,
    this.personCount = 0,
  });

  factory CityResponse.fromJson(Map<String, dynamic> json) => CityResponse(
        id: json['id'] as int,
        governorateId: json['governorateId'] as int,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String?,
        neighborhoodCount: json['neighborhoodCount'] as int? ?? 0,
        personCount: json['personCount'] as int? ?? 0,
      );

  City toEntity() => City(
        id: id,
        governorateId: governorateId,
        name: name,
        nameAr: nameAr,
        neighborhoodCount: neighborhoodCount,
        personCount: personCount,
      );
}

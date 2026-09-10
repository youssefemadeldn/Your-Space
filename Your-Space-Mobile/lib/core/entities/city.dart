import 'package:equatable/equatable.dart';

/// Level 2 of the location hierarchy — always user-owned, scoped to one
/// parent Governorate. Mirrors `CityProfileDto`.
class City extends Equatable {
  final int id;
  final int governorateId;
  final String name;
  final String? nameAr;
  final int neighborhoodCount;
  final int personCount;

  const City({
    required this.id,
    required this.governorateId,
    required this.name,
    this.nameAr,
    this.neighborhoodCount = 0,
    this.personCount = 0,
  });

  @override
  List<Object?> get props => [id, governorateId, name, nameAr, neighborhoodCount, personCount];
}

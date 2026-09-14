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
  final DateTime? updatedAt;

  const City({
    required this.id,
    required this.governorateId,
    required this.name,
    this.nameAr,
    this.neighborhoodCount = 0,
    this.personCount = 0,
    this.updatedAt,
  });

  /// Used by `CityListCubit` to merge the one-shot server-computed
  /// `neighborhoodCount` (design doc §8) onto a locally-cached row before
  /// display — the local drift cache never stores this field itself.
  City copyWith({int? neighborhoodCount, int? personCount}) => City(
        id: id,
        governorateId: governorateId,
        name: name,
        nameAr: nameAr,
        neighborhoodCount: neighborhoodCount ?? this.neighborhoodCount,
        personCount: personCount ?? this.personCount,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props =>
      [id, governorateId, name, nameAr, neighborhoodCount, personCount, updatedAt];
}

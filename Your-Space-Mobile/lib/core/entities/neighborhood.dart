import 'package:equatable/equatable.dart';

/// Level 3 (leaf) of the location hierarchy — always user-owned, scoped to
/// one parent City. Mirrors `NeighborhoodProfileDto`.
class Neighborhood extends Equatable {
  final int id;
  final int cityId;
  final String name;
  final String? nameAr;
  final int personCount;

  const Neighborhood({
    required this.id,
    required this.cityId,
    required this.name,
    this.nameAr,
    this.personCount = 0,
  });

  /// Used by `NeighborhoodListCubit` to merge the one-shot server-computed
  /// `personCount` (design doc §8) onto a locally-cached row before
  /// display — the local drift cache never stores this field itself.
  Neighborhood copyWith({int? personCount}) => Neighborhood(
        id: id,
        cityId: cityId,
        name: name,
        nameAr: nameAr,
        personCount: personCount ?? this.personCount,
      );

  @override
  List<Object?> get props => [id, cityId, name, nameAr, personCount];
}

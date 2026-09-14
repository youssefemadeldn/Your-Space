import 'package:equatable/equatable.dart';

/// Second classification tier under [Group], scoped to exactly one parent
/// group. Lives in core — consumed by the classification feature, the
/// Person wizard, and the Add Guests screen. Mirrors `SubGroupProfileDto`.
class SubGroup extends Equatable {
  final int id;
  final int groupId;
  final String name;
  final String? nameAr;
  final int personCount;

  const SubGroup({
    required this.id,
    required this.groupId,
    required this.name,
    this.nameAr,
    this.personCount = 0,
  });

  /// Used by `SubGroupListCubit` to merge the one-shot server-computed
  /// `personCount` (design doc §8) onto a locally-cached row before
  /// display — the local drift cache never stores this field itself.
  SubGroup copyWith({int? personCount}) => SubGroup(
        id: id,
        groupId: groupId,
        name: name,
        nameAr: nameAr,
        personCount: personCount ?? this.personCount,
      );

  @override
  List<Object?> get props => [id, groupId, name, nameAr, personCount];
}

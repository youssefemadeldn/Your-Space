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

  @override
  List<Object?> get props => [id, groupId, name, nameAr, personCount];
}

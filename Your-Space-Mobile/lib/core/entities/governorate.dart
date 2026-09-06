import 'package:equatable/equatable.dart';

/// Level 1 of the location hierarchy (Governorate -> City -> Neighborhood),
/// independent of Group/SubGroup. [isLocked] marks the 27 seeded/global rows
/// (can't be renamed or deleted) — user-created custom rows have it false.
/// Mirrors `GovernorateProfileDto`.
class Governorate extends Equatable {
  final int id;
  final String name;
  final String? nameAr;
  final bool isLocked;
  final int personCount;

  const Governorate({
    required this.id,
    required this.name,
    this.nameAr,
    this.isLocked = false,
    this.personCount = 0,
  });

  @override
  List<Object?> get props => [id, name, nameAr, isLocked, personCount];
}

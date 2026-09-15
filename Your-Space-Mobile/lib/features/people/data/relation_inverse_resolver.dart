import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';

/// Mobile-side port of the backend's `RelationInverseResolver` — needed
/// because Tier 2's optimistic local write (row 9.13) inserts the
/// auto-derived inverse row *before* the server confirms it, so the local
/// drift cache needs the same deterministic mapping the backend uses to
/// avoid ever showing an inaccurate placeholder type between the write and
/// the sync. `subjectGender` is always the gender of the row's own
/// `personId` (the "Y" in "Y's father is X"), never `relatedPersonId`,
/// regardless of direction.
///
/// Known limitation, inherited from the backend: Nephew/Niece -> Uncle/Aunt
/// loses the Maternal/Paternal distinction (can't tell which side without
/// walking the rest of the graph) — defaults to Paternal, same as the
/// backend.
class RelationInverseResolver {
  const RelationInverseResolver._();

  static RelationType resolve(RelationType original, Gender subjectGender) =>
      subjectGender == Gender.male ? _maleInverse[original]! : _femaleInverse[original]!;

  static const _maleInverse = {
    RelationType.father: RelationType.son,
    RelationType.mother: RelationType.son,
    RelationType.son: RelationType.father,
    RelationType.daughter: RelationType.father,
    RelationType.brother: RelationType.brother,
    RelationType.sister: RelationType.brother,
    RelationType.husband: RelationType.wife,
    RelationType.wife: RelationType.husband,
    RelationType.uncleMaternal: RelationType.nephew,
    RelationType.auntMaternal: RelationType.nephew,
    RelationType.unclePaternal: RelationType.nephew,
    RelationType.auntPaternal: RelationType.nephew,
    RelationType.nephew: RelationType.unclePaternal,
    RelationType.niece: RelationType.unclePaternal,
  };

  static const _femaleInverse = {
    RelationType.father: RelationType.daughter,
    RelationType.mother: RelationType.daughter,
    RelationType.son: RelationType.mother,
    RelationType.daughter: RelationType.mother,
    RelationType.brother: RelationType.sister,
    RelationType.sister: RelationType.sister,
    RelationType.husband: RelationType.wife,
    RelationType.wife: RelationType.husband,
    RelationType.uncleMaternal: RelationType.niece,
    RelationType.auntMaternal: RelationType.niece,
    RelationType.unclePaternal: RelationType.niece,
    RelationType.auntPaternal: RelationType.niece,
    RelationType.nephew: RelationType.auntPaternal,
    RelationType.niece: RelationType.auntPaternal,
  };
}

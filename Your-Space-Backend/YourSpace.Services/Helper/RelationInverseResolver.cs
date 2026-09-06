using YourSpace.Data.Enums;

namespace YourSpace.Services.Helper;

// Stateless domain lookup (not a DI service, same placement precedent as LocalizedTextResolver) —
// resolves the inverse of a PersonRelationship row. `subjectGender` is always the gender of the
// row's own PersonId (the "Y" in "Y's father is X"), never RelatedPersonId, regardless of
// direction — see relationship-engine-2026-08-05.md's inverse-derivation table.
//
// Known limitation, not silently handled: Nephew/Niece -> Uncle/Aunt loses the Maternal/Paternal
// distinction (can't tell which side without walking the rest of the graph). Defaults to Paternal
// on that one ambiguous direction — the far more common flow (Uncle/Aunt -> Nephew/Niece) is
// unaffected and always correct.
public static class RelationInverseResolver
{
    public static RelationType Resolve(RelationType original, Gender subjectGender) =>
        subjectGender == Gender.Male ? MaleInverse[original] : FemaleInverse[original];

    private static readonly Dictionary<RelationType, RelationType> MaleInverse = new()
    {
        [RelationType.Father] = RelationType.Son,
        [RelationType.Mother] = RelationType.Son,
        [RelationType.Son] = RelationType.Father,
        [RelationType.Daughter] = RelationType.Father,
        [RelationType.Brother] = RelationType.Brother,
        [RelationType.Sister] = RelationType.Brother,
        [RelationType.Husband] = RelationType.Wife,
        [RelationType.Wife] = RelationType.Husband,
        [RelationType.UncleMaternal] = RelationType.Nephew,
        [RelationType.AuntMaternal] = RelationType.Nephew,
        [RelationType.UnclePaternal] = RelationType.Nephew,
        [RelationType.AuntPaternal] = RelationType.Nephew,
        [RelationType.Nephew] = RelationType.UnclePaternal,
        [RelationType.Niece] = RelationType.UnclePaternal
    };

    private static readonly Dictionary<RelationType, RelationType> FemaleInverse = new()
    {
        [RelationType.Father] = RelationType.Daughter,
        [RelationType.Mother] = RelationType.Daughter,
        [RelationType.Son] = RelationType.Mother,
        [RelationType.Daughter] = RelationType.Mother,
        [RelationType.Brother] = RelationType.Sister,
        [RelationType.Sister] = RelationType.Sister,
        [RelationType.Husband] = RelationType.Wife,
        [RelationType.Wife] = RelationType.Husband,
        [RelationType.UncleMaternal] = RelationType.Niece,
        [RelationType.AuntMaternal] = RelationType.Niece,
        [RelationType.UnclePaternal] = RelationType.Niece,
        [RelationType.AuntPaternal] = RelationType.Niece,
        [RelationType.Nephew] = RelationType.AuntPaternal,
        [RelationType.Niece] = RelationType.AuntPaternal
    };
}

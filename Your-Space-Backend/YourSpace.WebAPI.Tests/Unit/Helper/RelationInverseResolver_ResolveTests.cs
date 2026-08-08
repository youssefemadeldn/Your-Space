using FluentAssertions;
using YourSpace.Data.Enums;
using YourSpace.Services.Helper;

namespace YourSpace.WebAPI.Tests.Unit.Helper;

// All 14 RelationType x 2 Gender combinations — the exact matrix the relationship engine's
// auto-derived-inverse behavior depends on (see relationship-engine-2026-08-05.md). Expected
// values are the real-world kinship pairing, independent of how the resolver happens to be
// implemented — a wrong edit to either inverse dictionary should fail one of these rows.
public class RelationInverseResolver_ResolveTests
{
    public static IEnumerable<object[]> Cases =>
    [
        // Parent/child — subject's father/mother, inverse is subject's son/daughter (by subject's own gender)
        [RelationType.Father, Gender.Male, RelationType.Son],
        [RelationType.Father, Gender.Female, RelationType.Daughter],
        [RelationType.Mother, Gender.Male, RelationType.Son],
        [RelationType.Mother, Gender.Female, RelationType.Daughter],
        [RelationType.Son, Gender.Male, RelationType.Father],
        [RelationType.Son, Gender.Female, RelationType.Mother],
        [RelationType.Daughter, Gender.Male, RelationType.Father],
        [RelationType.Daughter, Gender.Female, RelationType.Mother],

        // Siblings — inverse is a sibling, gendered by the subject
        [RelationType.Brother, Gender.Male, RelationType.Brother],
        [RelationType.Brother, Gender.Female, RelationType.Sister],
        [RelationType.Sister, Gender.Male, RelationType.Brother],
        [RelationType.Sister, Gender.Female, RelationType.Sister],

        // Spouses — always cross-gendered, independent of subject's own gender
        [RelationType.Husband, Gender.Male, RelationType.Wife],
        [RelationType.Husband, Gender.Female, RelationType.Wife],
        [RelationType.Wife, Gender.Male, RelationType.Husband],
        [RelationType.Wife, Gender.Female, RelationType.Husband],

        // Uncle/Aunt -> Nephew/Niece, gendered by the subject (the nephew/niece)
        [RelationType.UncleMaternal, Gender.Male, RelationType.Nephew],
        [RelationType.UncleMaternal, Gender.Female, RelationType.Niece],
        [RelationType.AuntMaternal, Gender.Male, RelationType.Nephew],
        [RelationType.AuntMaternal, Gender.Female, RelationType.Niece],
        [RelationType.UnclePaternal, Gender.Male, RelationType.Nephew],
        [RelationType.UnclePaternal, Gender.Female, RelationType.Niece],
        [RelationType.AuntPaternal, Gender.Male, RelationType.Nephew],
        [RelationType.AuntPaternal, Gender.Female, RelationType.Niece],

        // Nephew/Niece -> Uncle/Aunt — the one documented ambiguous direction (can't tell
        // Maternal/Paternal without walking the graph), defaults to Paternal regardless of subject gender.
        [RelationType.Nephew, Gender.Male, RelationType.UnclePaternal],
        [RelationType.Nephew, Gender.Female, RelationType.AuntPaternal],
        [RelationType.Niece, Gender.Male, RelationType.UnclePaternal],
        [RelationType.Niece, Gender.Female, RelationType.AuntPaternal],
    ];

    [Theory]
    [MemberData(nameof(Cases))]
    public void Resolves_the_correct_inverse_for_every_relation_type_and_subject_gender(
        RelationType original, Gender subjectGender, RelationType expectedInverse)
    {
        var result = RelationInverseResolver.Resolve(original, subjectGender);

        result.Should().Be(expectedInverse);
    }

    [Fact]
    public void Covers_all_fourteen_relation_types()
    {
        Cases.Select(c => (RelationType)c[0]).Distinct().Should().HaveCount(14);
    }
}

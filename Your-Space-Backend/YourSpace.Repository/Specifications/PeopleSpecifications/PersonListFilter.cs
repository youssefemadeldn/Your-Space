namespace YourSpace.Repository.Specifications.PeopleSpecifications;

// Filter set for the paginated People-screen listing — kept as its own type rather than growing
// PersonWithSpecs's constructors past readable positional-optional-param limits (5 dimensions:
// Group, SubGroup, Governorate, City, Neighborhood, plus free-text search).
public class PersonListFilter
{
    public int? GroupId { get; set; }
    public int? SubGroupId { get; set; }
    public int? GovernorateId { get; set; }
    public int? CityId { get; set; }
    public int? NeighborhoodId { get; set; }
    public string? Search { get; set; }
}

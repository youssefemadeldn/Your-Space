using FluentAssertions;
using NetArchTest.Rules;
using YourSpace.Repository.Repositories;
using YourSpace.Services.Helper;

namespace YourSpace.WebAPI.Tests.Architecture;

public class ArchitectureLayeringTests
{
    [Fact]
    public void Repository_assembly_does_not_depend_on_Services()
    {
        var result = Types.InAssembly(typeof(GenericRepository<,>).Assembly)
            .Should()
            .NotHaveDependencyOn("YourSpace.Services")
            .GetResult();

        result.IsSuccessful.Should().BeTrue(
            "Repository must stay below Services in the layer direction. " + result);
    }

    [Fact]
    public void Dtos_do_not_reference_EF_Core_or_entities()
    {
        var result = Types.InAssembly(typeof(ServiceResult<>).Assembly)
            .That()
            .ResideInNamespaceMatching(@"YourSpace\.Services\..*\.Dtos")
            .Should()
            .NotHaveDependencyOnAll("Microsoft.EntityFrameworkCore", "YourSpace.Data.Entities")
            .GetResult();

        result.IsSuccessful.Should().BeTrue(
            "DTOs are transport-only, not persistence-aware. " + result);
    }
}

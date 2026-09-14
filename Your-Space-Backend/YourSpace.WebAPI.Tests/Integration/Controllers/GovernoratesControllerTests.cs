using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using FluentAssertions;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GovernorateService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

public class GovernoratesControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { Converters = { new JsonStringEnumConverter() } };

    [Fact]
    public async Task Create_get_update_and_delete_custom_governorate_happy_path_succeeds()
    {
        var client = await factory.CreateAuthenticatedClientAsync("governorates.happy-path@example.com");

        var createResponse = await client.PostAsJsonAsync("/api/v1/Governorates", new CreateGovernorateDto { Name = "New Valley" });
        createResponse.StatusCode.Should().Be(HttpStatusCode.Created);
        var created = await DeserializeAsync<GovernorateDetailsDto>(createResponse);
        var governorateId = created.Data!.Id;
        created.Data.IsLocked.Should().BeFalse();

        var getResponse = await client.GetAsync($"/api/v1/Governorates/{governorateId}");
        getResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var updateResponse = await client.PutAsJsonAsync("/api/v1/Governorates", new UpdateGovernorateDto { Id = governorateId, Name = "New Valley (Updated)" });
        updateResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var updated = await DeserializeAsync<GovernorateDetailsDto>(updateResponse);
        updated.Data!.Name.Should().Be("New Valley (Updated)");

        // Explicit large page size — unlike Group, Governorate's list always has 27 global seeded
        // rows ahead of it (alphabetically), so the default page size can't be relied on to
        // include a just-created row on page 1.
        var listResponse = await client.GetAsync("/api/v1/Governorates?pageIndex=1&pageSize=50");
        var list = await DeserializeAsync<PaginatedResultDto<GovernorateProfileDto>>(listResponse);
        list.Data!.Items.Should().Contain(g => g.Id == governorateId);

        var deleteResponse = await client.DeleteAsync($"/api/v1/Governorates/{governorateId}");
        deleteResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var getAfterDeleteResponse = await client.GetAsync($"/api/v1/Governorates/{governorateId}");
        getAfterDeleteResponse.StatusCode.Should().Be(HttpStatusCode.NotFound, "the governorate is soft-deleted and must no longer resolve");
    }

    [Fact]
    public async Task List_includes_global_seeded_governorates_alongside_the_caller_s_own()
    {
        var client = await factory.CreateAuthenticatedClientAsync("governorates.global-visibility@example.com");

        var listResponse = await client.GetAsync("/api/v1/Governorates?pageIndex=1&pageSize=50");
        var list = await DeserializeAsync<PaginatedResultDto<GovernorateProfileDto>>(listResponse);

        list.Data!.Items.Should().Contain(g => g.Name == "Cairo" && g.IsLocked);
    }

    [Fact]
    public async Task Update_and_delete_are_rejected_for_a_locked_global_governorate()
    {
        var client = await factory.CreateAuthenticatedClientAsync("governorates.locked-edit@example.com");
        var listResponse = await client.GetAsync("/api/v1/Governorates?pageIndex=1&pageSize=50");
        var list = await DeserializeAsync<PaginatedResultDto<GovernorateProfileDto>>(listResponse);
        var cairoId = list.Data!.Items.Single(g => g.Name == "Cairo").Id;

        var updateResponse = await client.PutAsJsonAsync("/api/v1/Governorates", new UpdateGovernorateDto { Id = cairoId, Name = "Renamed Cairo" });
        updateResponse.StatusCode.Should().Be(HttpStatusCode.Conflict);

        var deleteResponse = await client.DeleteAsync($"/api/v1/Governorates/{cairoId}");
        deleteResponse.StatusCode.Should().Be(HttpStatusCode.Conflict);
    }

    [Fact]
    public async Task Rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/Governorates");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Changes_reflects_create_update_and_soft_delete_via_an_increasing_syncversion_cursor()
    {
        var client = await factory.CreateAuthenticatedClientAsync("governorates.changes@example.com");

        var created = await DeserializeAsync<GovernorateDetailsDto>(
            await client.PostAsJsonAsync("/api/v1/Governorates", new CreateGovernorateDto { Name = "New Valley" }));
        var governorateId = created.Data!.Id;
        var createdVersion = created.Data.SyncVersion;

        var beforeCreate = await DeserializeAsync<GovernorateChangesDto>(
            await client.GetAsync($"/api/v1/Governorates/changes?since={createdVersion - 1}"));
        beforeCreate.Data!.Upserts.Should().Contain(g => g.Id == governorateId);
        beforeCreate.Data.TombstoneIds.Should().NotContain(governorateId);

        var atCreatedVersion = await DeserializeAsync<GovernorateChangesDto>(
            await client.GetAsync($"/api/v1/Governorates/changes?since={createdVersion}"));
        atCreatedVersion.Data!.Upserts.Should().NotContain(g => g.Id == governorateId, "already seen up to this cursor");

        var updated = await DeserializeAsync<GovernorateDetailsDto>(
            await client.PutAsJsonAsync("/api/v1/Governorates", new UpdateGovernorateDto { Id = governorateId, Name = "New Valley (Updated)" }));
        updated.Data!.SyncVersion.Should().BeGreaterThan(createdVersion, "an update must bump the cursor, not just create");

        var afterUpdate = await DeserializeAsync<GovernorateChangesDto>(
            await client.GetAsync($"/api/v1/Governorates/changes?since={createdVersion}"));
        afterUpdate.Data!.Upserts.Should().Contain(g => g.Id == governorateId && g.Name == "New Valley (Updated)");

        await client.DeleteAsync($"/api/v1/Governorates/{governorateId}");

        var afterDelete = await DeserializeAsync<GovernorateChangesDto>(
            await client.GetAsync($"/api/v1/Governorates/changes?since={updated.Data.SyncVersion}"));
        afterDelete.Data!.TombstoneIds.Should().Contain(governorateId);
        afterDelete.Data.Upserts.Should().NotContain(g => g.Id == governorateId);
    }

    [Fact]
    public async Task Changes_includes_global_seeded_rows_on_a_first_ever_pull()
    {
        // The widened OwnerUserId==null||== predicate (GovernorateWithSpecs's delta ctor) is the
        // one real divergence from Group/Person's always-owned shape — verify it end-to-end
        // against the real database, not just the mocked-repository unit tests.
        var client = await factory.CreateAuthenticatedClientAsync("governorates.changes-global@example.com");

        var response = await DeserializeAsync<GovernorateChangesDto>(
            await client.GetAsync("/api/v1/Governorates/changes?since=0&pageSize=500"));

        response.Data!.Upserts.Should().Contain(g => g.Name == "Cairo" && g.IsLocked);
    }

    [Fact]
    public async Task Changes_rejects_a_negative_since_cursor()
    {
        var client = await factory.CreateAuthenticatedClientAsync("governorates.changes-invalid@example.com");

        var response = await client.GetAsync("/api/v1/Governorates/changes?since=-1");

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Changes_rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/Governorates/changes");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}

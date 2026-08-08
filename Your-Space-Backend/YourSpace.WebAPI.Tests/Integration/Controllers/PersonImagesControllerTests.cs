using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using YourSpace.Data.Enums;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GovernorateService.Dtos;
using YourSpace.Services.Services.GroupService.Dtos;
using YourSpace.Services.Services.PersonImageService.Dtos;
using YourSpace.Services.Services.PersonService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

public class PersonImagesControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private static MultipartFormDataContent MakeFileContent()
    {
        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent([0xFF, 0xD8, 0xFF, 0xE0]); // fake JPEG bytes — never actually decoded
        fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("image/jpeg");
        content.Add(fileContent, "File", "photo.jpg");
        return content;
    }

    private async Task<int> CreatePersonAsync(HttpClient client, string name)
    {
        var groupResponse = await client.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = $"{name}'s Group" });
        var group = await DeserializeAsync<GroupDetailsDto>(groupResponse);

        var governorateResponse = await client.PostAsJsonAsync("/api/v1/Governorates", new CreateGovernorateDto { Name = $"{name}'s Governorate" });
        var governorate = await DeserializeAsync<GovernorateDetailsDto>(governorateResponse);

        var personResponse = await client.PostAsJsonAsync("/api/v1/Persons", new CreatePersonDto
        {
            Name = name,
            GroupId = group.Data!.Id,
            GovernorateId = governorate.Data!.Id,
            Gender = Gender.Male
        });
        var person = await DeserializeAsync<PersonDetailsDto>(personResponse);
        return person.Data!.Id;
    }

    [Fact]
    public async Task Upload_list_set_primary_and_delete_happy_path_succeeds()
    {
        var client = await factory.CreateAuthenticatedClientAsync("person-images.happy-path@example.com");
        var personId = await CreatePersonAsync(client, "Ahmed");

        var firstUploadResponse = await client.PostAsync($"/api/v1/persons/{personId}/images", MakeFileContent());
        firstUploadResponse.StatusCode.Should().Be(HttpStatusCode.Created);
        var first = await DeserializeAsync<PersonImageDto>(firstUploadResponse);
        first.Data!.IsPrimary.Should().BeTrue("the first image for a person is auto-marked primary");

        var secondUploadResponse = await client.PostAsync($"/api/v1/persons/{personId}/images", MakeFileContent());
        var second = await DeserializeAsync<PersonImageDto>(secondUploadResponse);
        second.Data!.IsPrimary.Should().BeFalse();

        var listResponse = await client.GetAsync($"/api/v1/persons/{personId}/images");
        var list = await DeserializeAsync<List<PersonImageDto>>(listResponse);
        list.Data.Should().HaveCount(2);

        var setPrimaryResponse = await client.PostAsync($"/api/v1/persons/{personId}/images/{second.Data.Id}/set-primary", null);
        setPrimaryResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var setPrimary = await DeserializeAsync<PersonImageDto>(setPrimaryResponse);
        setPrimary.Data!.IsPrimary.Should().BeTrue();

        var deleteResponse = await client.DeleteAsync($"/api/v1/persons/{personId}/images/{second.Data.Id}");
        deleteResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        // The deleted image was primary — the remaining one should have been promoted.
        var listAfterDeleteResponse = await client.GetAsync($"/api/v1/persons/{personId}/images");
        var listAfterDelete = await DeserializeAsync<List<PersonImageDto>>(listAfterDeleteResponse);
        listAfterDelete.Data.Should().ContainSingle(i => i.Id == first.Data.Id && i.IsPrimary);

        factory.R2Storage.DeletedObjects.Should().Contain(o => o.BucketName == "people");
    }

    [Fact]
    public async Task Rejects_the_seventh_image_for_one_person()
    {
        var client = await factory.CreateAuthenticatedClientAsync("person-images.max-reached@example.com");
        var personId = await CreatePersonAsync(client, "Sara");

        for (var i = 0; i < 6; i++)
        {
            var response = await client.PostAsync($"/api/v1/persons/{personId}/images", MakeFileContent());
            response.StatusCode.Should().Be(HttpStatusCode.Created);
        }

        var seventhResponse = await client.PostAsync($"/api/v1/persons/{personId}/images", MakeFileContent());
        seventhResponse.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        var seventh = await DeserializeAsync<PersonImageDto>(seventhResponse);
        seventh.ErrorCode.Should().Be("PersonImage.MaxReached");
    }

    [Fact]
    public async Task Returns_not_found_for_a_person_owned_by_someone_else()
    {
        var ownerClient = await factory.CreateAuthenticatedClientAsync("person-images.owner@example.com");
        var personId = await CreatePersonAsync(ownerClient, "Owner's Person");

        var otherClient = await factory.CreateAuthenticatedClientAsync("person-images.intruder@example.com");
        var response = await otherClient.PostAsync($"/api/v1/persons/{personId}/images", MakeFileContent());

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/persons/1/images");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}

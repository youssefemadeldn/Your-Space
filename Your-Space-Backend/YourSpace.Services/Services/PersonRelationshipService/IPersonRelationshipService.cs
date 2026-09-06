using YourSpace.Services.Helper;
using YourSpace.Services.Services.PersonRelationshipService.Dtos;

namespace YourSpace.Services.Services.PersonRelationshipService;

public interface IPersonRelationshipService
{
    Task<ServiceResult<IReadOnlyList<PersonRelationshipProfileDto>>> GetAllAsync(string ownerUserId, int personId);
    Task<ServiceResult<PersonRelationshipDetailsDto>> CreateAsync(string ownerUserId, int personId, CreatePersonRelationshipDto dto);
    Task<ServiceResult> DeleteAsync(string ownerUserId, int personId, int relationshipId);
}

using YourSpace.Data.Entities;

namespace YourSpace.Repository.Specifications.AuthSpecifications;

// Every refresh token for the user, revoked or not — feeds a full account deletion
// (ActiveRefreshTokensByUserSpecs only covers the still-valid ones).
public class AllRefreshTokensByUserSpecs : BaseSpecification<RefreshToken>
{
    public AllRefreshTokensByUserSpecs(string userId)
        : base(rt => rt.UserId == userId)
    {
    }
}

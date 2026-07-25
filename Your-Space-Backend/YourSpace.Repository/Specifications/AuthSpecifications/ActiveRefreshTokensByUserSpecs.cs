using YourSpace.Data.Entities;

namespace YourSpace.Repository.Specifications.AuthSpecifications;

public class ActiveRefreshTokensByUserSpecs : BaseSpecification<RefreshToken>
{
    public ActiveRefreshTokensByUserSpecs(string userId)
        : base(rt => rt.UserId == userId && rt.RevokedAt == null)
    {
    }
}

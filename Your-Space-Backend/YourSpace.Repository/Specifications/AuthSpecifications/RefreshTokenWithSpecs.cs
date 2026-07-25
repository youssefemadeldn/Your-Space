using YourSpace.Data.Entities;

namespace YourSpace.Repository.Specifications.AuthSpecifications;

public class RefreshTokenWithSpecs : BaseSpecification<RefreshToken>
{
    public RefreshTokenWithSpecs(string tokenHash) : base(rt => rt.TokenHash == tokenHash)
    {
        AddInclude(rt => rt.User);
    }
}

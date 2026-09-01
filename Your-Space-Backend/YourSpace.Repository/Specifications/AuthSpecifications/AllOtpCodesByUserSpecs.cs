using YourSpace.Data.Entities;

namespace YourSpace.Repository.Specifications.AuthSpecifications;

// Every OTP code for the user, consumed or not — feeds a full account deletion
// (ActiveOtpCodeByUserSpecs only covers the unconsumed one).
public class AllOtpCodesByUserSpecs<TEntity> : BaseSpecification<TEntity> where TEntity : class, IOtpCode
{
    public AllOtpCodesByUserSpecs(string userId)
        : base(oc => oc.UserId == userId)
    {
    }
}

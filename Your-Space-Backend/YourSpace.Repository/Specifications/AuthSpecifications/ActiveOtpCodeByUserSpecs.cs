using YourSpace.Data.Entities;

namespace YourSpace.Repository.Specifications.AuthSpecifications;

public class ActiveOtpCodeByUserSpecs<TEntity> : BaseSpecification<TEntity> where TEntity : class, IOtpCode
{
    public ActiveOtpCodeByUserSpecs(string userId)
        : base(oc => oc.UserId == userId && oc.ConsumedAt == null)
    {
        ApplyOrderByDescending(oc => oc.CreatedAt);
    }
}

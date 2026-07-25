using Microsoft.AspNetCore.Identity;
using Moq;
using YourSpace.Data.Entities;

namespace YourSpace.WebAPI.Tests.Common.MockFactories;

public static class UserManagerMockFactory
{
    public static Mock<UserManager<AppUser>> Create()
    {
        var store = new Mock<IUserStore<AppUser>>();
        return new Mock<UserManager<AppUser>>(store.Object, null!, null!, null!, null!, null!, null!, null!, null!);
    }
}

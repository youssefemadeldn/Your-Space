using Microsoft.Extensions.Localization;
using Moq;
using YourSpace.Services.Resources;

namespace YourSpace.WebAPI.Tests.Common.MockFactories;

// Every new service takes IStringLocalizer<SharedResource> for its messages (CLAUDE.md Rule 8).
// Unit tests only assert on ErrorCode/behavior, not translated text, so this echoes the resource
// key back as the "localized" value rather than loading real .resx data.
public static class LocalizerMockFactory
{
    public static Mock<IStringLocalizer<SharedResource>> Create()
    {
        var mock = new Mock<IStringLocalizer<SharedResource>>();
        mock.Setup(l => l[It.IsAny<string>()]).Returns((string key) => new LocalizedString(key, key));
        mock.Setup(l => l[It.IsAny<string>(), It.IsAny<object[]>()]).Returns((string key, object[] _) => new LocalizedString(key, key));
        return mock;
    }
}

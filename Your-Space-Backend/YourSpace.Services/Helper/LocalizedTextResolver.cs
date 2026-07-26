using System.Globalization;

namespace YourSpace.Services.Helper;

// Shared Rule 8 resolution: a bilingual entity field (e.g. Group.Name/NameAr) always resolves to
// ONE DTO field based on the current request's culture — the client never sees both.
public static class LocalizedTextResolver
{
    public static string Resolve(string value, string? valueAr) =>
        CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar" && !string.IsNullOrEmpty(valueAr)
            ? valueAr
            : value;
}

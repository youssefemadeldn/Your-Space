namespace YourSpace.WebAPI.Helpers;

public static class ConnectionStringResolver
{
    public static string Resolve(IConfiguration configuration, ILogger logger)
    {
        var configured = configuration["ConnectionStrings:YourSpaceDB"];
        var resolved = !string.IsNullOrWhiteSpace(configured)
            ? configured
            : ResolveFromDatabaseUrl(Environment.GetEnvironmentVariable("DATABASE_URL"));

        if (string.IsNullOrWhiteSpace(resolved))
            throw new InvalidOperationException(
                "No connection string configured. Set ConnectionStrings:YourSpaceDB or the DATABASE_URL environment variable.");

        logger.LogInformation("Resolved database connection string: {ConnectionString}", Mask(resolved));
        return resolved;
    }

    private static string? ResolveFromDatabaseUrl(string? databaseUrl)
    {
        if (string.IsNullOrWhiteSpace(databaseUrl))
            return null;

        var uri = new Uri(databaseUrl);
        var userInfo = uri.UserInfo.Split(':', 2);
        var username = Uri.UnescapeDataString(userInfo[0]);
        var password = userInfo.Length > 1 ? Uri.UnescapeDataString(userInfo[1]) : string.Empty;
        var database = uri.AbsolutePath.TrimStart('/');

        return $"Host={uri.Host};Port={uri.Port};Database={database};Username={username};Password={password};SSL Mode=Require;Trust Server Certificate=true";
    }

    private static string Mask(string connectionString)
    {
        var parts = connectionString.Split(';', StringSplitOptions.RemoveEmptyEntries);
        var masked = parts.Select(p =>
            p.TrimStart().StartsWith("Password=", StringComparison.OrdinalIgnoreCase) ? "Password=***" : p);
        return string.Join(';', masked);
    }
}

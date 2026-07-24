# Setup

## Prerequisites

- .NET SDK 10.0.202+
- PostgreSQL (local instance for development)
- Redis (local instance for development)

## User secrets

Real connection strings and signing keys never live in `appsettings*.json` (shape only). Set them locally via `dotnet user-secrets`:

```bash
dotnet user-secrets init --project YourSpace.WebAPI
dotnet user-secrets set "ConnectionStrings:YourSpaceDB" "Host=localhost;Port=5432;Database=yourspace;Username=postgres;Password=<local-only>" --project YourSpace.WebAPI
dotnet user-secrets set "Jwt:Key" "<dev-only-signing-key>" --project YourSpace.WebAPI
```

In deployed environments, these come from environment variables or a secrets manager — never baked into an image or config file. `ConnectionStrings:YourSpaceDB` can also be supplied via a `DATABASE_URL` environment variable in `postgres://user:pass@host:port/db` form (the Railway/Render/Coolify convention); see `YourSpace.WebAPI/Helpers/ConnectionStringResolver.cs`.

## Migrations

EF Core migrations live in `YourSpace.Data`, but must be run against `YourSpace.WebAPI` as the startup project (it owns the DI configuration that resolves the connection string):

```bash
dotnet ef migrations add <MigrationName> --project YourSpace.Data --startup-project YourSpace.WebAPI
dotnet ef database update --project YourSpace.Data --startup-project YourSpace.WebAPI
```

## Running

```bash
dotnet build
dotnet run --project YourSpace.WebAPI
```

Swagger UI is only enabled in `Development`. Two environments are configured: `Development` (verbose logging, Swagger UI) and `Production` (HSTS, no Swagger, generic error messages).

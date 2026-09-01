# Use .NET 10 SDK for building
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project files and restore (separate layer so this is cached unless a .csproj changes)
COPY ["YourSpace.WebAPI/YourSpace.WebAPI.csproj", "YourSpace.WebAPI/"]
COPY ["YourSpace.Services/YourSpace.Services.csproj", "YourSpace.Services/"]
COPY ["YourSpace.Repository/YourSpace.Repository.csproj", "YourSpace.Repository/"]
COPY ["YourSpace.Data/YourSpace.Data.csproj", "YourSpace.Data/"]
RUN dotnet restore "YourSpace.WebAPI/YourSpace.WebAPI.csproj"

# Copy the rest of the code and publish
COPY . .
WORKDIR "/src/YourSpace.WebAPI"
RUN dotnet publish "YourSpace.WebAPI.csproj" -c Release -o /app/publish

# Use runtime image
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

# Deployment platforms (Coolify/Render/etc.) route to this port dynamically, usually 8080
ENV ASPNETCORE_URLS=http://+:8080
# Set RUN_MIGRATIONS_ON_STARTUP=true on the single instance that should apply pending EF Core
# migrations before Kestrel binds (see Program.cs). Leave unset elsewhere — other instances and
# the explicit `dotnet ef database update` deploy step cover the rest.
EXPOSE 8080

ENTRYPOINT ["dotnet", "YourSpace.WebAPI.dll"]

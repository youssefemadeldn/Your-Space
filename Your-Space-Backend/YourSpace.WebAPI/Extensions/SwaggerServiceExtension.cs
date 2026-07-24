using Asp.Versioning.ApiExplorer;
using NSwag;
using NSwag.Generation.Processors.Security;

namespace YourSpace.WebAPI.Extensions;

public static class SwaggerServiceExtension
{
    public static IServiceCollection AddSwaggerDocumentation(this IServiceCollection services)
    {
        services.AddEndpointsApiExplorer();

        // A temporary provider is needed here purely to read the already-registered API version
        // descriptions at startup — it resolves no scoped services, only IApiVersionDescriptionProvider.
#pragma warning disable ASP0000
        using var tempProvider = services.BuildServiceProvider();
#pragma warning restore ASP0000
        var versionProvider = tempProvider.GetRequiredService<IApiVersionDescriptionProvider>();

        foreach (var description in versionProvider.ApiVersionDescriptions)
        {
            services.AddOpenApiDocument(config =>
            {
                config.DocumentName = description.GroupName;
                config.ApiGroupNames = [description.GroupName];
                config.Title = "YourSpace API";
                config.Version = description.ApiVersion.ToString();

                config.AddSecurity("Bearer", [], new OpenApiSecurityScheme
                {
                    Type = OpenApiSecuritySchemeType.Http,
                    Scheme = "bearer",
                    BearerFormat = "JWT",
                    Description = "JWT Authorization header using the Bearer scheme."
                });
                config.OperationProcessors.Add(new AspNetCoreOperationSecurityScopeProcessor("Bearer"));
            });
        }

        return services;
    }
}

using Asp.Versioning;
using FluentValidation;
using FluentValidation.AspNetCore;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Repositories;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.AuthService;
using YourSpace.Services.Services.TokenService;

namespace YourSpace.WebAPI.Helpers;

public static class ServiceRegistration
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        // Repository / Unit of Work
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped(typeof(IGenericRepository<,>), typeof(GenericRepository<,>));

        // Mapping
        services.AddAutoMapper(cfg => { }, AppDomain.CurrentDomain.GetAssemblies());

        // Validation — anchor updated to a real validator's type once the first feature adds one
        services.AddValidatorsFromAssemblyContaining<ServiceResult<object>>();
        services.AddFluentValidationAutoValidation();

        // Auth
        services.AddScoped<IAuthService, AuthService>();
        services.AddSingleton<ITokenService, TokenService>();

        // API versioning
        services.AddApiVersioning(options =>
        {
            options.DefaultApiVersion = new ApiVersion(1, 0);
            options.AssumeDefaultVersionWhenUnspecified = true;
            options.ReportApiVersions = true;
        }).AddApiExplorer(options =>
        {
            options.GroupNameFormat = "'v'VVV";
            options.SubstituteApiVersionInUrl = true;
        });

        // Authorization — hierarchical RBAC: SuperAdminOnly is a strict subset of AdminOnly
        services.AddAuthorization(options =>
        {
            options.AddPolicy("AdminOnly", policy => policy.RequireRole(RoleNames.AdminRoles));
            options.AddPolicy("SuperAdminOnly", policy => policy.RequireRole(RoleNames.SuperAdmin));
        });

        return services;
    }
}

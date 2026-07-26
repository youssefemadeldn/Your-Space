using Asp.Versioning;
using FluentValidation;
using FluentValidation.AspNetCore;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Repositories;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.AuthService;
using YourSpace.Services.Services.EventGuestService;
using YourSpace.Services.Services.EventService;
using YourSpace.Services.Services.GroupService;
using YourSpace.Services.Services.OtpService;
using YourSpace.Services.Services.PersonOccasionHistoryService;
using YourSpace.Services.Services.PersonService;
using YourSpace.Services.Services.TokenService;
using YourSpace.Services.Services.UserSettingsService;

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
        services.AddScoped<IOtpService, OtpService>();
        services.AddSingleton<ITokenService, TokenService>();

        // People, Groups, Events (Invitation Planner)
        services.AddScoped<IGroupService, GroupService>();
        services.AddScoped<IPersonService, PersonService>();
        services.AddScoped<IPersonOccasionHistoryService, PersonOccasionHistoryService>();
        services.AddScoped<IEventService, EventService>();
        services.AddScoped<IEventGuestService, EventGuestService>();
        services.AddScoped<IUserSettingsService, UserSettingsService>();

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

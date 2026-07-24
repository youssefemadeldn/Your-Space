using Asp.Versioning;
using FluentValidation;
using FluentValidation.AspNetCore;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Repositories;
using YourSpace.Services.Helper;

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

        // Authorization — policies added per-feature
        services.AddAuthorization();

        return services;
    }
}

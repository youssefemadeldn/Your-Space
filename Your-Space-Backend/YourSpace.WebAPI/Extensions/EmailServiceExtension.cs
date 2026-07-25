using YourSpace.Services.Services.EmailService;

namespace YourSpace.WebAPI.Extensions;

public static class EmailServiceExtension
{
    public static IServiceCollection AddEmailService(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<EmailOptions>(configuration.GetSection(EmailOptions.SectionName));
        services.AddSingleton<IEmailSender, EmailSender>();

        return services;
    }
}

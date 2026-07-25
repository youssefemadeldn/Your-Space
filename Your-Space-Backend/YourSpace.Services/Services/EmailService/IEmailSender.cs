namespace YourSpace.Services.Services.EmailService;

public interface IEmailSender
{
    Task SendEmailAsync(string toEmail, string subject, string htmlBody);
}

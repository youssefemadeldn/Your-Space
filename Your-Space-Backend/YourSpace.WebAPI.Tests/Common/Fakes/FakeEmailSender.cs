using YourSpace.Services.Services.EmailService;

namespace YourSpace.WebAPI.Tests.Common.Fakes;

public class FakeEmailSender : IEmailSender
{
    public List<(string ToEmail, string Subject, string HtmlBody)> SentEmails { get; } = [];

    public Task SendEmailAsync(string toEmail, string subject, string htmlBody)
    {
        SentEmails.Add((toEmail, subject, htmlBody));
        return Task.CompletedTask;
    }
}

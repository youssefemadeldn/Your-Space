using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MimeKit;

namespace YourSpace.Services.Services.EmailService;

public class EmailSender(IOptions<EmailOptions> options, ILogger<EmailSender> logger) : IEmailSender
{
    private readonly EmailOptions _options = options.Value;

    public async Task SendEmailAsync(string toEmail, string subject, string htmlBody)
    {
        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(_options.SenderName, _options.SenderEmail));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = subject;
        message.Body = new BodyBuilder { HtmlBody = htmlBody }.ToMessageBody();

        using var client = new SmtpClient();

        client.CheckCertificateRevocation = false;

        logger.LogInformation("Sending email {Subject} to {ToEmail}", subject, toEmail);

        await client.ConnectAsync(
            _options.SmtpHost,
            _options.SmtpPort,
            _options.EnableSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None);
        await client.AuthenticateAsync(_options.SmtpUsername, _options.SmtpPassword);
        await client.SendAsync(message);
        await client.DisconnectAsync(true);
    }
}

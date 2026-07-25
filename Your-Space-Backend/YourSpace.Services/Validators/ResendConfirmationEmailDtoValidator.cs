using FluentValidation;
using YourSpace.Services.Services.AuthService.Dtos;

namespace YourSpace.Services.Validators;

public class ResendConfirmationEmailDtoValidator : AbstractValidator<ResendConfirmationEmailDto>
{
    public ResendConfirmationEmailDtoValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress();
    }
}

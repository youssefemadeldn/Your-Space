using FluentValidation;
using YourSpace.Services.Services.AuthService.Dtos;

namespace YourSpace.Services.Validators;

public class ConfirmEmailDtoValidator : AbstractValidator<ConfirmEmailDto>
{
    public ConfirmEmailDtoValidator()
    {
        RuleFor(x => x.UserId).NotEmpty();
        RuleFor(x => x.Token).NotEmpty();
    }
}

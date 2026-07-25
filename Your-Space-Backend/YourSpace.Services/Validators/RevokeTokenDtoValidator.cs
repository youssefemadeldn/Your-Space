using FluentValidation;
using YourSpace.Services.Services.AuthService.Dtos;

namespace YourSpace.Services.Validators;

public class RevokeTokenDtoValidator : AbstractValidator<RevokeTokenDto>
{
    public RevokeTokenDtoValidator()
    {
        RuleFor(x => x.RefreshToken).NotEmpty();
    }
}

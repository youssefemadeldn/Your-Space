using FluentValidation;
using YourSpace.Services.Services.AuthService.Dtos;

namespace YourSpace.Services.Validators;

public class DeleteAccountDtoValidator : AbstractValidator<DeleteAccountDto>
{
    public DeleteAccountDtoValidator()
    {
        RuleFor(x => x.Password).NotEmpty();
    }
}

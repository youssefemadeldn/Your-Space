using FluentValidation;
using YourSpace.Services.Services.AuthService.Dtos;

namespace YourSpace.Services.Validators;

// Mirrors RegisterDtoValidator's FirstName/LastName/PhoneNumber rules exactly — same
// pre-existing hardcoded-English convention as the rest of AuthService (see
// RegisterDtoValidator's comment); not retroactively localized here either.
public class UpdateProfileDtoValidator : AbstractValidator<UpdateProfileDto>
{
    public UpdateProfileDtoValidator()
    {
        RuleFor(x => x.FirstName).NotEmpty().MaximumLength(100);
        RuleFor(x => x.LastName).NotEmpty().MaximumLength(100);

        RuleFor(x => x.PhoneNumber)
            .NotEmpty()
            .Matches(@"^\+?[1-9]\d{7,14}$").WithMessage("Phone number must be a valid international format, e.g. +201234567890.");
    }
}

using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.AuthService.Dtos;

namespace YourSpace.Services.Validators;

public class RegisterDtoValidator : AbstractValidator<RegisterDto>
{
    public RegisterDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        // The 6 rules below are pre-existing hardcoded-English literals — an inconsistency
        // relative to CreatePersonDtoValidator's localized pattern. Out of scope here; only the
        // new Gender rule below follows the localized convention. Flagged, not silently fixed.
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(256);

        RuleFor(x => x.Password).NotEmpty().MustBeStrongPassword();

        RuleFor(x => x.ConfirmPassword)
            .Equal(x => x.Password).WithMessage("Passwords do not match.");

        RuleFor(x => x.FirstName).NotEmpty().MaximumLength(100);
        RuleFor(x => x.LastName).NotEmpty().MaximumLength(100);

        RuleFor(x => x.PhoneNumber)
            .NotEmpty()
            .Matches(@"^\+?[1-9]\d{7,14}$").WithMessage("Phone number must be a valid international format, e.g. +201234567890.");

        RuleFor(x => x.Gender)
            .IsInEnum().WithMessage(localizer["Auth.Register.Gender.Required"]);
    }
}

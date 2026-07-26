using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.PersonService.Dtos;

namespace YourSpace.Services.Validators;

public class CreatePersonDtoValidator : AbstractValidator<CreatePersonDto>
{
    public CreatePersonDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(localizer["Person.Name.Required"])
            .MaximumLength(200).WithMessage(localizer["Person.Name.MaxLength"]);

        RuleFor(x => x.PhoneNumber)
            .Matches(@"^\+?[1-9]\d{7,14}$").WithMessage(localizer["Person.PhoneNumber.InvalidFormat"])
            .When(x => !string.IsNullOrEmpty(x.PhoneNumber));

        RuleFor(x => x.GroupId)
            .GreaterThan(0).WithMessage(localizer["Person.GroupId.Invalid"]);
    }
}

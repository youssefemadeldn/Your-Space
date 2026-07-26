using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.PersonService.Dtos;

namespace YourSpace.Services.Validators;

public class UpdatePersonDtoValidator : AbstractValidator<UpdatePersonDto>
{
    public UpdatePersonDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Id).GreaterThan(0);

        When(x => x.Name is not null, () =>
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage(localizer["Person.Name.Required"])
                .MaximumLength(200).WithMessage(localizer["Person.Name.MaxLength"]);
        });

        RuleFor(x => x.PhoneNumber)
            .Matches(@"^\+?[1-9]\d{7,14}$").WithMessage(localizer["Person.PhoneNumber.InvalidFormat"])
            .When(x => !string.IsNullOrEmpty(x.PhoneNumber));

        RuleFor(x => x.GroupId)
            .GreaterThan(0).WithMessage(localizer["Person.GroupId.Invalid"])
            .When(x => x.GroupId is not null);
    }
}

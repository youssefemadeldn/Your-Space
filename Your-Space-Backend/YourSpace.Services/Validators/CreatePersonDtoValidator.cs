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

        RuleFor(x => x.PhoneNumber2)
            .Matches(@"^\+?[1-9]\d{7,14}$").WithMessage(localizer["Person.PhoneNumber2.InvalidFormat"])
            .When(x => !string.IsNullOrEmpty(x.PhoneNumber2));

        RuleFor(x => x.Notes)
            .MaximumLength(2000).WithMessage(localizer["Person.Notes.MaxLength"]);

        RuleFor(x => x.Gender)
            .IsInEnum().WithMessage(localizer["Person.Gender.Required"]);

        RuleFor(x => x.GroupId)
            .GreaterThan(0).WithMessage(localizer["Person.GroupId.Invalid"]);

        RuleFor(x => x.SubGroupId)
            .GreaterThan(0).WithMessage(localizer["Person.SubGroupId.Invalid"])
            .When(x => x.SubGroupId is not null);

        RuleFor(x => x.GovernorateId)
            .GreaterThan(0).WithMessage(localizer["Person.GovernorateId.Invalid"]);

        RuleFor(x => x.CityId)
            .GreaterThan(0).WithMessage(localizer["Person.CityId.Invalid"])
            .When(x => x.CityId is not null);

        RuleFor(x => x.NeighborhoodId)
            .GreaterThan(0).WithMessage(localizer["Person.NeighborhoodId.Invalid"])
            .When(x => x.NeighborhoodId is not null);
    }
}

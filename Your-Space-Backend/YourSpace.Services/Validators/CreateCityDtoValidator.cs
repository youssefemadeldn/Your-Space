using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.CityService.Dtos;

namespace YourSpace.Services.Validators;

public class CreateCityDtoValidator : AbstractValidator<CreateCityDto>
{
    public CreateCityDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(localizer["City.Name.Required"])
            .MaximumLength(200).WithMessage(localizer["City.Name.MaxLength"]);

        RuleFor(x => x.NameAr)
            .MaximumLength(200).WithMessage(localizer["City.Name.MaxLength"])
            .When(x => x.NameAr is not null);
    }
}

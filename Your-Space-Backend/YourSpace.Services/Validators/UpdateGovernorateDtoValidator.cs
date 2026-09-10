using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.GovernorateService.Dtos;

namespace YourSpace.Services.Validators;

public class UpdateGovernorateDtoValidator : AbstractValidator<UpdateGovernorateDto>
{
    public UpdateGovernorateDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Id).GreaterThan(0);

        When(x => x.Name is not null, () =>
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage(localizer["Governorate.Name.Required"])
                .MaximumLength(200).WithMessage(localizer["Governorate.Name.MaxLength"]);
        });

        RuleFor(x => x.NameAr)
            .MaximumLength(200).WithMessage(localizer["Governorate.Name.MaxLength"])
            .When(x => x.NameAr is not null);
    }
}

using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.NeighborhoodService.Dtos;

namespace YourSpace.Services.Validators;

public class CreateNeighborhoodDtoValidator : AbstractValidator<CreateNeighborhoodDto>
{
    public CreateNeighborhoodDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(localizer["Neighborhood.Name.Required"])
            .MaximumLength(200).WithMessage(localizer["Neighborhood.Name.MaxLength"]);

        RuleFor(x => x.NameAr)
            .MaximumLength(200).WithMessage(localizer["Neighborhood.Name.MaxLength"])
            .When(x => x.NameAr is not null);
    }
}

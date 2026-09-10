using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.SubGroupService.Dtos;

namespace YourSpace.Services.Validators;

public class CreateSubGroupDtoValidator : AbstractValidator<CreateSubGroupDto>
{
    public CreateSubGroupDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(localizer["SubGroup.Name.Required"])
            .MaximumLength(200).WithMessage(localizer["SubGroup.Name.MaxLength"]);

        RuleFor(x => x.NameAr)
            .MaximumLength(200).WithMessage(localizer["SubGroup.Name.MaxLength"])
            .When(x => x.NameAr is not null);
    }
}

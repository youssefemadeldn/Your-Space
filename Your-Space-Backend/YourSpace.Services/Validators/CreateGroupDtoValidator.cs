using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.GroupService.Dtos;

namespace YourSpace.Services.Validators;

public class CreateGroupDtoValidator : AbstractValidator<CreateGroupDto>
{
    public CreateGroupDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(localizer["Group.Name.Required"])
            .MaximumLength(200).WithMessage(localizer["Group.Name.MaxLength"]);

        RuleFor(x => x.NameAr)
            .MaximumLength(200).WithMessage(localizer["Group.Name.MaxLength"])
            .When(x => x.NameAr is not null);
    }
}

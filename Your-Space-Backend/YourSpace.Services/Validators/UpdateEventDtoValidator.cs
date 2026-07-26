using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.EventService.Dtos;

namespace YourSpace.Services.Validators;

public class UpdateEventDtoValidator : AbstractValidator<UpdateEventDto>
{
    public UpdateEventDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Id).GreaterThan(0);

        When(x => x.Name is not null, () =>
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage(localizer["Event.Name.Required"])
                .MaximumLength(200).WithMessage(localizer["Event.Name.MaxLength"]);
        });

        RuleFor(x => x.NameAr).MaximumLength(200).When(x => x.NameAr is not null);
        RuleFor(x => x.Notes).MaximumLength(2000).When(x => x.Notes is not null);
    }
}

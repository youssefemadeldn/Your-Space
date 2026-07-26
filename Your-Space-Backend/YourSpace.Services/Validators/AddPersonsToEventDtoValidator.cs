using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.EventGuestService.Dtos;

namespace YourSpace.Services.Validators;

public class AddPersonsToEventDtoValidator : AbstractValidator<AddPersonsToEventDto>
{
    public AddPersonsToEventDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.PersonIds)
            .NotEmpty().WithMessage(localizer["EventGuest.PersonIds.Required"])
            .Must(ids => ids.Distinct().Count() == ids.Count).WithMessage(localizer["EventGuest.PersonIds.NoDuplicates"]);
    }
}

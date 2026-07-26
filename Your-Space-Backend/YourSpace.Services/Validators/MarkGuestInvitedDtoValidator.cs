using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.EventGuestService.Dtos;

namespace YourSpace.Services.Validators;

public class MarkGuestInvitedDtoValidator : AbstractValidator<MarkGuestInvitedDto>
{
    public MarkGuestInvitedDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.InviteMethod)
            .IsInEnum().WithMessage(localizer["EventGuest.InviteMethod.Required"]);
    }
}

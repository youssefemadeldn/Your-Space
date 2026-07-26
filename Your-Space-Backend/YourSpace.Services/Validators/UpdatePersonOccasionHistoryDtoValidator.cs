using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;

namespace YourSpace.Services.Validators;

public class UpdatePersonOccasionHistoryDtoValidator : AbstractValidator<UpdatePersonOccasionHistoryDto>
{
    public UpdatePersonOccasionHistoryDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Id).GreaterThan(0);

        // Only catches the DTO-local case (InvitedMe explicitly set to false in this same request).
        // The service additionally forces InviteMethod to null against the *resolved* (post-merge)
        // state, since a validator can't see what InvitedMe already is on an existing row.
        RuleFor(x => x.InviteMethod)
            .Null().WithMessage(localizer["PersonOccasionHistory.InviteMethod.MustBeNullWhenNotInvitedMe"])
            .When(x => x.InvitedMe == false);

        RuleFor(x => x.OccasionDate)
            .LessThanOrEqualTo(DateTime.UtcNow).WithMessage(localizer["PersonOccasionHistory.OccasionDate.CannotBeFuture"])
            .When(x => x.OccasionDate is not null);

        RuleFor(x => x.OccasionName).MaximumLength(200).When(x => x.OccasionName is not null);
        RuleFor(x => x.Notes).MaximumLength(2000).When(x => x.Notes is not null);
    }
}

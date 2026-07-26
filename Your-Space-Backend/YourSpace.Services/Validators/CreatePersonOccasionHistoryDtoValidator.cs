using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;

namespace YourSpace.Services.Validators;

public class CreatePersonOccasionHistoryDtoValidator : AbstractValidator<CreatePersonOccasionHistoryDto>
{
    public CreatePersonOccasionHistoryDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.InviteMethod)
            .Null().WithMessage(localizer["PersonOccasionHistory.InviteMethod.MustBeNullWhenNotInvitedMe"])
            .When(x => !x.InvitedMe);

        RuleFor(x => x.OccasionDate)
            .LessThanOrEqualTo(DateTime.UtcNow).WithMessage(localizer["PersonOccasionHistory.OccasionDate.CannotBeFuture"])
            .When(x => x.OccasionDate is not null);

        RuleFor(x => x.OccasionName).MaximumLength(200);
        RuleFor(x => x.Notes).MaximumLength(2000);
    }
}

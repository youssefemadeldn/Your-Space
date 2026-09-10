using FluentValidation;
using YourSpace.Services.Services.PersonRelationshipService.Dtos;

namespace YourSpace.Services.Validators;

public class CreatePersonRelationshipDtoValidator : AbstractValidator<CreatePersonRelationshipDto>
{
    public CreatePersonRelationshipDtoValidator()
    {
        RuleFor(x => x.RelatedPersonId).GreaterThan(0);
        RuleFor(x => x.RelationType).IsInEnum();
    }
}

---
name: T5-validator
governed-by: CLAUDE.md "Validation" · CLAUDE.md Architecture rule 8 ("Localization") · dotnet_feature_prompt.md Rule 2 & Rule 8
---

# T5 — FluentValidation Validator

One class per request DTO. Lives in `<Solution>.Services/Validators/`, picked up automatically by the assembly scan already wired in `ServiceRegistration` — no manual registration per validator.

---

## `Create<Entity>DtoValidator.cs`

```csharp
using FluentValidation;
using Microsoft.Extensions.Localization;
using <Solution>.Services.Resources;
using <Solution>.Services.Services.<Feature>Service.Dtos;

namespace <Solution>.Services.Validators;

public class Create<Entity>DtoValidator : AbstractValidator<Create<Entity>Dto>
{
    public Create<Entity>DtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(localizer["<Entity>.Name.Required"])
            .MaximumLength(200).WithMessage(localizer["<Entity>.Name.MaxLength"]);

        RuleFor(x => x.<PriceOrAmount>)
            .GreaterThan(0).WithMessage(localizer["<Entity>.<PriceOrAmount>.GreaterThanZero"]);

        RuleFor(x => x.<RelatedEntity>Id)
            .GreaterThan(0).WithMessage(localizer["<Entity>.<RelatedEntity>Id.Invalid"]);

        // Nested collection — validate each item without a separate top-level validator class:
        // RuleForEach(x => x.Items).ChildRules(item => {
        //     item.RuleFor(i => i.Quantity).GreaterThan(0);
        // });
    }
}
```

## `Update<Entity>DtoValidator.cs`

```csharp
using FluentValidation;
using Microsoft.Extensions.Localization;
using <Solution>.Services.Resources;
using <Solution>.Services.Services.<Feature>Service.Dtos;

namespace <Solution>.Services.Validators;

public class Update<Entity>DtoValidator : AbstractValidator<Update<Entity>Dto>
{
    public Update<Entity>DtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Id).GreaterThan(0);

        // Nullable fields on an update DTO mean "leave unchanged if omitted" (see T4-dto.md) —
        // only validate a field's *value* when it was actually supplied:
        When(x => x.Name is not null, () =>
        {
            RuleFor(x => x.Name!)
                .NotEmpty().WithMessage(localizer["<Entity>.Name.Required"])
                .MaximumLength(200).WithMessage(localizer["<Entity>.Name.MaxLength"]);
        });

        When(x => x.<PriceOrAmount>.HasValue, () =>
        {
            RuleFor(x => x.<PriceOrAmount>!.Value)
                .GreaterThan(0).WithMessage(localizer["<Entity>.<PriceOrAmount>.GreaterThanZero"]);
        });
    }
}
```

---

## Notes

- **One validator class per request DTO, no exceptions** — including update DTOs, which are the most commonly skipped in practice (see `dotnet_feature_prompt.md` §7 anti-patterns table).
- **Every `.WithMessage(...)` pulls from `IStringLocalizer<SharedResource>`, never a string literal** — inject it via the validator's constructor (validators are resolved from DI, so constructor injection works normally). Add the key to both `SharedResource.en.resx` and `SharedResource.ar.resx` in the same commit that introduces it. See CLAUDE.md "Localization" and Rule 8.
- **Validators are pure and side-effect-free by default** — they check shape, ranges, and required-ness. A validator does **not** query the database.
- **`MustAsync` for a genuine cross-field/database check is the rare exception, not the default** — e.g. "this SKU must not already exist." Use it deliberately, understand it runs on every request against this DTO (a performance cost), and prefer keeping true business-rule checks (not simple uniqueness) as service-layer guard clauses instead (`dotnet_feature_prompt.md` Rule 2's "domain invariant" carve-out).
- **Never duplicate a validator's rule as a manual `if` in the service** — if the service is checking something the validator already checks, delete the duplicate from the service; the validator runs first and the service will never see an invalid DTO.

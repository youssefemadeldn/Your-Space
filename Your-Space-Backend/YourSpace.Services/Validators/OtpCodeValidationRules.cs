using FluentValidation;
using YourSpace.Services.Services.OtpService;

namespace YourSpace.Services.Validators;

public static class OtpCodeValidationRules
{
    public static IRuleBuilderOptions<T, string> MustBeValidOtpCode<T>(this IRuleBuilder<T, string> ruleBuilder) =>
        ruleBuilder
            .Matches($@"^\d{{{OtpConstants.CodeLength}}}$")
            .WithMessage($"Code must be exactly {OtpConstants.CodeLength} digits.");
}

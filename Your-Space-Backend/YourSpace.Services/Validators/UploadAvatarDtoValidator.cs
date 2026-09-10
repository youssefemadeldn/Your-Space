using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Helper;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.AuthService.Dtos;

namespace YourSpace.Services.Validators;

public class UploadAvatarDtoValidator : AbstractValidator<UploadAvatarDto>
{
    public UploadAvatarDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.File)
            .NotNull().WithMessage(localizer["Avatar.File.Required"]);

        RuleFor(x => x.File.Length)
            .LessThanOrEqualTo(FileUploadConstants.MaxImageSizeBytes).WithMessage(localizer["Avatar.File.TooLarge"])
            .When(x => x.File is not null);

        RuleFor(x => x.File.ContentType)
            .Must(contentType => FileUploadConstants.AllowedImageContentTypes.Contains(contentType))
            .WithMessage(localizer["Avatar.File.InvalidType"])
            .When(x => x.File is not null);
    }
}

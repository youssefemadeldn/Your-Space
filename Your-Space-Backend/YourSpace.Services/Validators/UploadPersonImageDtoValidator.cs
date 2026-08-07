using FluentValidation;
using Microsoft.Extensions.Localization;
using YourSpace.Services.Helper;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.PersonImageService.Dtos;

namespace YourSpace.Services.Validators;

public class UploadPersonImageDtoValidator : AbstractValidator<UploadPersonImageDto>
{
    public UploadPersonImageDtoValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.File)
            .NotNull().WithMessage(localizer["PersonImage.File.Required"]);

        RuleFor(x => x.File.Length)
            .LessThanOrEqualTo(FileUploadConstants.MaxImageSizeBytes).WithMessage(localizer["PersonImage.File.TooLarge"])
            .When(x => x.File is not null);

        RuleFor(x => x.File.ContentType)
            .Must(contentType => FileUploadConstants.AllowedImageContentTypes.Contains(contentType))
            .WithMessage(localizer["PersonImage.File.InvalidType"])
            .When(x => x.File is not null);
    }
}

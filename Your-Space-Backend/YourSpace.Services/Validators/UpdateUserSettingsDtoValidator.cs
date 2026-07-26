using FluentValidation;
using YourSpace.Services.Services.UserSettingsService.Dtos;

namespace YourSpace.Services.Validators;

// The single bool field has no invalid shape to check — this class exists mainly so a future
// second settings field has somewhere to attach a rule, and for Rule 2 consistency (every
// mutating DTO gets a validator class, picked up by the existing assembly scan).
public class UpdateUserSettingsDtoValidator : AbstractValidator<UpdateUserSettingsDto>;

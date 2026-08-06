// `hide TextDirection` — easy_localization re-exports intl's own TextDirection
// class (LTR/RTL/UNKNOWN), which would otherwise shadow Flutter's TextDirection
// (ltr/rtl) used for forcing LTR on email/phone fields under Arabic locale.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_input_label.dart';
import 'package:your_space_mobile/core/widgets/app_password_input.dart';
import 'package:your_space_mobile/core/widgets/gender_chip_group.dart';

/// The pure-presentation field list, extracted out of `register_screen.dart`
/// to keep that file under the ~250-line screen-folder threshold. Not shared
/// with any other screen — lives in this screen's own folder, not `widgets/`.
class RegisterFormFields extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? firstNameError;
  final String? lastNameError;
  final String? emailError;
  final String? phoneError;
  final String? passwordError;
  final String? confirmPasswordError;
  final Gender? selectedGender;
  final String? genderError;
  final ValueChanged<String> onFirstNameChanged;
  final ValueChanged<String> onLastNameChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onConfirmPasswordChanged;
  final ValueChanged<Gender> onGenderChanged;

  const RegisterFormFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.firstNameError,
    required this.lastNameError,
    required this.emailError,
    required this.phoneError,
    required this.passwordError,
    required this.confirmPasswordError,
    required this.selectedGender,
    required this.genderError,
    required this.onFirstNameChanged,
    required this.onLastNameChanged,
    required this.onEmailChanged,
    required this.onPhoneChanged,
    required this.onPasswordChanged,
    required this.onConfirmPasswordChanged,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppInput(
                label: 'auth.firstName'.tr(),
                controller: firstNameController,
                errorText: firstNameError,
                onChanged: onFirstNameChanged,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AppInput(
                label: 'auth.lastName'.tr(),
                controller: lastNameController,
                errorText: lastNameError,
                onChanged: onLastNameChanged,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        AppInput(
          label: 'auth.email'.tr(),
          hintText: 'you@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          controller: emailController,
          errorText: emailError,
          onChanged: onEmailChanged,
        ),
        SizedBox(height: 14.h),
        AppInput(
          label: 'auth.phone'.tr(),
          hintText: '+201234567890',
          prefixIcon: Icons.call_outlined,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          controller: phoneController,
          errorText: phoneError,
          onChanged: onPhoneChanged,
        ),
        SizedBox(height: 14.h),
        AppInputLabel('auth.gender'.tr()),
        SizedBox(height: 8.h),
        GenderChipGroup(selected: selectedGender, onChanged: onGenderChanged),
        if (genderError != null) ...[
          SizedBox(height: 6.h),
          Text(genderError!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
        ],
        SizedBox(height: 14.h),
        AppPasswordInput(
          label: 'auth.password'.tr(),
          controller: passwordController,
          errorText: passwordError,
          helperText: 'auth.passwordRule'.tr(),
          onChanged: onPasswordChanged,
        ),
        SizedBox(height: 14.h),
        AppPasswordInput(
          label: 'auth.confirmPassword'.tr(),
          controller: confirmPasswordController,
          errorText: confirmPasswordError,
          onChanged: onConfirmPasswordChanged,
        ),
      ],
    );
  }
}

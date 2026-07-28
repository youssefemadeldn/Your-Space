import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';

/// Shared "Your Space" wordmark header used across the auth screens.
/// [compact] is used on screens with more content below (Register, Confirm
/// Email, Forgot/Reset Password) to leave more vertical room for the form.
class AuthLogoHeader extends StatelessWidget {
  final bool compact;

  const AuthLogoHeader({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final style = compact ? AppTextStyles.headlineSmall : AppTextStyles.displayMedium;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 20.h : 48.h),
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RichText(
            text: TextSpan(
              style: style.copyWith(color: AppColors.secondary),
              children: [
                const TextSpan(text: 'Your '),
                TextSpan(text: 'Space', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

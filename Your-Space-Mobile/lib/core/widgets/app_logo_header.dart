import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared "Your Space" logo mark + wordmark — used across the auth screens
/// and Home. [compact] leaves more vertical room for content below (Register,
/// Confirm Email, Forgot/Reset Password, Home). [centered] controls whether
/// the lockup centers itself (auth screens) or hugs the leading edge (Home's
/// inline header, shown above the greeting). [logoSize]/[padding] override
/// the size/spacing defaults derived from [compact] when a caller needs a
/// closer match to a specific design frame.
class AppLogoHeader extends StatelessWidget {
  final bool compact;
  final bool centered;
  final double? logoSize;
  final EdgeInsetsGeometry? padding;

  const AppLogoHeader({
    super.key,
    this.compact = false,
    this.centered = true,
    this.logoSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final style = compact ? AppTextStyles.headlineSmall : AppTextStyles.displayMedium;
    final resolvedLogoSize = logoSize ?? (compact ? 32.w : 40.w);
    final resolvedPadding = padding ?? EdgeInsets.symmetric(vertical: compact ? 20.h : 48.h);

    final lockup = Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/images/logo.svg',
            width: resolvedLogoSize,
            height: resolvedLogoSize,
          ),
          SizedBox(width: 10.w),
          RichText(
            text: TextSpan(
              style: style.copyWith(color: AppColors.secondary),
              children: [
                const TextSpan(text: 'Your '),
                TextSpan(text: 'Space', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: resolvedPadding,
      child: centered
          ? Center(child: lockup)
          : Align(alignment: AlignmentDirectional.centerStart, child: lockup),
    );
  }
}

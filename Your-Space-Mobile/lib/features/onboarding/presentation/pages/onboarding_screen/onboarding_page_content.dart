import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';

/// One onboarding slide's static content — icon, headline, body. No new
/// illustration assets; reuses the same Material icons already used
/// elsewhere in the app for the same concepts (groups, events, history).
class OnboardingPageContent extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String bodyKey;

  const OnboardingPageContent({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder + minHeight keeps the content centered on a normal phone
    // viewport, but lets it scroll instead of overflowing on a short/squat
    // one (a non-phone aspect ratio, or a small device) — same reasoning as
    // CLAUDE.md's "never stack fixed sections without a scroll wrapper" rule.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.w,
                height: 120.w,
                decoration: const BoxDecoration(
                  color: AppColors.brandRedSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 56.w, color: AppColors.primary),
              ),
              SizedBox(height: 32.h),
              Text(
                titleKey.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall,
              ),
              SizedBox(height: 12.h),
              Text(
                bodyKey.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

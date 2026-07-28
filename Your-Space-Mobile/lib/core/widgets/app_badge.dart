import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppBadgeTone { success, warning, error, info, brand, neutral }

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeTone tone;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.icon,
  });

  Color get _backgroundColor {
    switch (tone) {
      case AppBadgeTone.success:
        return AppColors.tintSuccess;
      case AppBadgeTone.warning:
        return AppColors.tintWarning;
      case AppBadgeTone.error:
        return AppColors.tintError;
      case AppBadgeTone.info:
        return AppColors.tintInfo;
      case AppBadgeTone.brand:
        return AppColors.brandRedSoft;
      case AppBadgeTone.neutral:
        return AppColors.divider;
    }
  }

  Color get _foregroundColor {
    switch (tone) {
      case AppBadgeTone.success:
        return AppColors.success;
      case AppBadgeTone.warning:
        return AppColors.warning;
      case AppBadgeTone.error:
        return AppColors.error;
      case AppBadgeTone.info:
        return AppColors.info;
      case AppBadgeTone.brand:
        return AppColors.primary;
      case AppBadgeTone.neutral:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = _foregroundColor;

    return Container(
      padding:
          EdgeInsetsDirectional.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14.w, color: fg),
            SizedBox(width: 4.w),
          ],
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: fg)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final int? count;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.icon,
    this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primary : AppColors.textSecondary;
    final bg = selected ? AppColors.brandRedSoft : AppColors.inputFill;

    return Material(
      color: bg,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.transparent,
          width: selected ? 1 : 0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              EdgeInsetsDirectional.symmetric(horizontal: 14.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16.w, color: fg),
                SizedBox(width: 6.w),
              ],
              Text(label, style: AppTextStyles.labelLarge.copyWith(color: fg)),
              if (count != null) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsetsDirectional.symmetric(
                      horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text('$count',
                      style: AppTextStyles.labelSmall.copyWith(color: fg)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

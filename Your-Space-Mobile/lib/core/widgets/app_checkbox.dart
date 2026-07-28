import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppCheckbox extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final String? label;

  const AppCheckbox({
    super.key,
    required this.checked,
    this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final checkbox = Checkbox(
      value: checked,
      onChanged: onChanged == null ? null : (value) => onChanged!(value ?? false),
      activeColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    if (label == null) return checkbox;

    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!checked),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          checkbox,
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              label!,
              style: AppTextStyles.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

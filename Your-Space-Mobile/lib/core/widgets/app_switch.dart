import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppSwitch extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final String? label;

  const AppSwitch({
    super.key,
    required this.checked,
    this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final toggle = Switch(
      value: checked,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.primary,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: AppColors.divider,
    );

    if (label == null) return toggle;

    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!checked),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label!, style: AppTextStyles.bodyMedium),
          SizedBox(width: 8.w),
          toggle,
        ],
      ),
    );
  }
}

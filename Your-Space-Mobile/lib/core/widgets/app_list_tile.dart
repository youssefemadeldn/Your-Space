import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? avatarName;
  final IconData? icon;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;
  final bool divider;
  final VoidCallback? onTap;

  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.avatarName,
    this.icon,
    this.iconColor,
    this.titleColor,
    this.trailing,
    this.divider = false,
    this.onTap,
  });

  String get _initials {
    final name = avatarName?.trim();
    if (name == null || name.isEmpty) return '';
    final parts = name.split(RegExp(r'\s+'));
    final first = parts.first.substring(0, 1);
    final second =
        parts.length > 1 && parts[1].isNotEmpty ? parts[1].substring(0, 1) : '';
    return (first + second).toUpperCase();
  }

  Widget get _leading {
    final hasAvatarName = avatarName != null && avatarName!.trim().isNotEmpty;
    if (hasAvatarName) {
      return CircleAvatar(
        radius: 20.r,
        backgroundColor: AppColors.brandRedSoft,
        child: Text(
          _initials,
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
        ),
      );
    }
    return CircleAvatar(
      radius: 20.r,
      backgroundColor: AppColors.inputFill,
      child: Icon(
        icon ?? Icons.person_rounded,
        size: 20.w,
        color: iconColor ?? AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      onTap: onTap,
      contentPadding:
          EdgeInsetsDirectional.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: _leading,
      title: Text(
        title,
        style: titleColor == null
            ? AppTextStyles.titleMedium
            : AppTextStyles.titleMedium.copyWith(color: titleColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: trailing,
    );

    if (!divider) return tile;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        Padding(
          padding: EdgeInsetsDirectional.only(start: 68.w),
          child: const Divider(height: 1),
        ),
      ],
    );
  }
}

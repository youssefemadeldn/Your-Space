import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool dark;

  const AppAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.dark = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      toolbarHeight: 56.h,
      leading: onBack == null
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack,
            ),
      actions: trailing == null ? null : [trailing!],
      backgroundColor: dark ? AppColors.secondary : null,
      foregroundColor: dark ? Colors.white : null,
      titleTextStyle:
          dark ? AppTextStyles.titleLarge.copyWith(color: Colors.white) : null,
    );
  }
}

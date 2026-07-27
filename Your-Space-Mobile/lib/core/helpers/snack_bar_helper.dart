import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:injectable/injectable.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

@lazySingleton
class SnackBarHelper {
  final GlobalKey<NavigatorState> _navigatorKey;

  SnackBarHelper(this._navigatorKey);

  void showSuccess(String message) => _show(message, AppColors.success);

  void showError(String message) => _show(message, AppColors.error);

  void showInfo(String message) => _show(message, AppColors.primary);

  void showWarning(String message) => _show(message, AppColors.warning);

  void _show(String message, Color backgroundColor) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
    );
  }
}

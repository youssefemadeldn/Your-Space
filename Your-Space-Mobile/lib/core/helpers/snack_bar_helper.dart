import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:injectable/injectable.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

@lazySingleton
class SnackBarHelper {
  final GlobalKey<NavigatorState> _navigatorKey;

  SnackBarHelper(this._navigatorKey);

  void showSuccess(String message, {String? actionLabel, VoidCallback? onAction}) =>
      _show(message, AppColors.success, actionLabel: actionLabel, onAction: onAction);

  void showError(String message, {String? actionLabel, VoidCallback? onAction}) =>
      _show(message, AppColors.error, actionLabel: actionLabel, onAction: onAction);

  void showInfo(String message, {String? actionLabel, VoidCallback? onAction}) =>
      _show(message, AppColors.primary, actionLabel: actionLabel, onAction: onAction);

  void showWarning(String message, {String? actionLabel, VoidCallback? onAction}) =>
      _show(message, AppColors.warning, actionLabel: actionLabel, onAction: onAction);

  void _show(
    String message,
    Color backgroundColor, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
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
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: AppColors.surface,
                onPressed: onAction ?? () {},
              ),
      ),
    );
  }
}

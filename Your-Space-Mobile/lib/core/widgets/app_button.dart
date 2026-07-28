import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, text, dark, soft }

enum AppButtonSize { sm, md }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool fullWidth;
  final bool loading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.fullWidth = false,
    this.loading = false,
  });

  bool get _isDisabled => onPressed == null;

  bool get _isInteractive => !_isDisabled && !loading;

  Color get _backgroundColor {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
      case AppButtonVariant.text:
        return Colors.transparent;
      case AppButtonVariant.dark:
        return AppColors.secondary;
      case AppButtonVariant.soft:
        return AppColors.brandRedSoft;
    }
  }

  Color get _foregroundColor {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.dark:
        return AppColors.surface;
      case AppButtonVariant.secondary:
      case AppButtonVariant.text:
      case AppButtonVariant.soft:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = size == AppButtonSize.md ? 52.h : 40.h;
    final horizontalPadding = size == AppButtonSize.md ? 28.w : 20.w;
    final radius = BorderRadius.circular(24.r);
    final foreground = _foregroundColor;
    final textStyle = (size == AppButtonSize.md
            ? AppTextStyles.titleMedium
            : AppTextStyles.labelLarge)
        .copyWith(color: foreground);

    // Row(mainAxisSize.min) hugs its content's natural width regardless of
    // whether the ancestor gives a bounded or unbounded width constraint —
    // unlike Center/Align, which expand to fill any *bounded* max-width. That
    // distinction is why this button reaches for Row here instead of Center
    // to lay out its content: a Center wrapper would silently stretch every
    // non-fullWidth button to fill its parent (e.g. inside a Column), since
    // Column gives a bounded (not unbounded) width constraint.
    final contentChildren = loading
        ? [
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(foreground),
              ),
            ),
          ]
        : [
            if (icon != null) ...[
              Icon(icon, size: 20.w, color: foreground),
              SizedBox(width: 8.w),
            ],
            Text(label, style: textStyle),
          ];

    final button = Material(
      color: _backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: variant == AppButtonVariant.secondary
            ? BorderSide(color: AppColors.primary)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _isInteractive ? onPressed : null,
        child: Container(
          height: height,
          padding:
              EdgeInsetsDirectional.symmetric(horizontal: horizontalPadding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: contentChildren,
          ),
        ),
      ),
    );

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: variant == AppButtonVariant.primary && !_isDisabled
            ? AppShadows.brand
            : null,
      ),
      child: button,
    );

    return Opacity(
      opacity: _isDisabled ? 0.4 : 1.0,
      child: fullWidth
          ? SizedBox(width: double.infinity, child: decorated)
          : decorated,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Static utility — takes [BuildContext] at the call site, unlike
/// [DialogHelper]/[SnackBarHelper] which hold an injected navigator key.
class BottomSheetHelper {
  BottomSheetHelper._();

  static Future<T?> showAppBottomSheet<T>(
    BuildContext context,
    Widget child, {
    bool isScrollable = false,
    double? maxHeightFraction,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollable,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final content = Container(
          constraints: maxHeightFraction != null
              ? BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * maxHeightFraction,
                )
              : null,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  isScrollable ? Flexible(child: child) : child,
                ],
              ),
            ),
          ),
        );
        return content;
      },
    );
  }
}

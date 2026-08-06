import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Fixed 4-item Home/Groups/People/Events nav. Default (`onTap == null`) calls
/// `context.go()` to the matching tab route. The `onTap` override exists so
/// `lib/dev/widget_gallery_main.dart` (a bare `MaterialApp`, not `.router`) can
/// demo this widget without a real `GoRouter` in scope.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppBottomNav({super.key, required this.currentIndex, this.onTap});

  static const _icons = [
    Icons.home_rounded,
    Icons.groups_rounded,
    Icons.people_alt_rounded,
    Icons.event_rounded,
    Icons.settings_rounded,
  ];

  static const _routes = [
    AppRoutes.home,
    AppRoutes.groups,
    AppRoutes.people,
    AppRoutes.events,
    AppRoutes.settings,
  ];

  static const _labelKeys = ['nav.home', 'nav.groups', 'nav.people', 'nav.events', 'nav.settings'];

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64.h,
          child: Row(
            children: List.generate(_icons.length, (index) {
              final selected = index == currentIndex;
              final color = selected ? AppColors.primary : AppColors.textHint;
              return Expanded(
                child: InkWell(
                  onTap: () => _handleTap(context, index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_icons[index], color: color, size: 24.w),
                      SizedBox(height: 2.h),
                      Text(
                        _labelKeys[index].tr(),
                        style: AppTextStyles.labelSmall.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

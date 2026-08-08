import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';

class AppTabs extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const AppTabs({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onChanged,
  });

  Widget _tab(int index) {
    final selected = index == activeIndex;
    return GestureDetector(
      onTap: () => onChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: selected ? AppShadows.soft : null,
        ),
        alignment: Alignment.center,
        child: Text(
          tabs[index],
          style: AppTextStyles.labelLarge.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // More than 3 tabs (e.g. Add Guests' 6-way split) can't fit evenly-flexed
    // labels on a phone width — falls back to a horizontally-scrolling row of
    // intrinsically-sized tabs instead. 3 or fewer keeps the original
    // fill-the-container behavior unchanged.
    final content = tabs.length > 3
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [for (var i = 0; i < tabs.length; i++) _tab(i)]),
          )
        : Row(children: [for (var i = 0; i < tabs.length; i++) Expanded(child: _tab(i))]);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: content,
    );
  }
}

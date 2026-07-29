import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../helpers/bottom_sheet_helper.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_input_label.dart';

/// Trigger renders as an input-fill pill (matching [AppInput]'s visual
/// language); options open via [BottomSheetHelper] rather than the design
/// system's web-style inline overlay — more idiomatic on mobile, no new plumbing.
class AppSelect extends StatelessWidget {
  final String? label;
  final String? value;
  final String? placeholder;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const AppSelect({
    super.key,
    this.label,
    required this.value,
    this.placeholder,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  Future<void> _openPicker(BuildContext context) async {
    final selected = await BottomSheetHelper.showAppBottomSheet<String>(
      context,
      // `BottomSheetHelper`'s outer DecoratedBox sits between the sheet's own
      // Material and this content — ListTile paints its background/ink on
      // the nearest Material ancestor, so without this wrapper those effects
      // would be hidden behind the DecoratedBox (Flutter raises this as a
      // debug-mode assertion, not just a cosmetic quirk).
      Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (option) => ListTile(
                  title: Text(option, style: AppTextStyles.bodyLarge),
                  trailing:
                      option == value ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                  onTap: () => Navigator.of(context).pop(option),
                ),
              )
              .toList(),
        ),
      ),
      isScrollable: true,
      maxHeightFraction: 0.6,
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final trigger = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? () => _openPicker(context) : null,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          height: 52.h,
          padding: EdgeInsetsDirectional.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? placeholder ?? '',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: value == null ? AppColors.textHint : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 22.w),
            ],
          ),
        ),
      ),
    );

    if (label == null) return trigger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppInputLabel(label!),
        SizedBox(height: 8.h),
        trigger,
      ],
    );
  }
}

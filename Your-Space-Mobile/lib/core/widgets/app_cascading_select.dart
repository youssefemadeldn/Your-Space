import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../helpers/bottom_sheet_helper.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_input_label.dart';

/// An option in an [AppCascadingSelect] picker — id/label pair (unlike
/// [AppSelect], which is string-only).
class AppCascadingSelectOption {
  final int id;
  final String label;

  const AppCascadingSelectOption({required this.id, required this.label});
}

/// Cascading picker for parent-scoped hierarchies (Group→Subgroup,
/// Governorate→City→Neighborhood): extends [AppSelect]'s trigger+bottom-sheet
/// foundation with id/label pairing, a disabled/greyed state for when the
/// parent hasn't been picked yet, and an inline "+ Add new" row that swaps
/// to a text field + confirm button in the same sheet.
class AppCascadingSelect extends StatelessWidget {
  final String? label;
  final String? valueLabel;
  final String? placeholder;
  final bool enabled;
  final List<AppCascadingSelectOption> options;
  final ValueChanged<int> onSelected;
  final bool allowInlineAdd;
  final String addNewLabel;
  final Future<int?> Function(String name)? onInlineAdd;
  final String? manageLabel;
  final VoidCallback? onManageTap;
  final String? emptyLabel;

  const AppCascadingSelect({
    super.key,
    this.label,
    this.valueLabel,
    this.placeholder,
    this.enabled = true,
    required this.options,
    required this.onSelected,
    this.allowInlineAdd = false,
    this.addNewLabel = 'Add new',
    this.onInlineAdd,
    this.manageLabel,
    this.onManageTap,
    this.emptyLabel,
  });

  Future<void> _openPicker(BuildContext context) async {
    final selectedId = await BottomSheetHelper.showAppBottomSheet<int>(
      context,
      _CascadingSelectSheet(
        options: options,
        selectedLabel: valueLabel,
        allowInlineAdd: allowInlineAdd,
        addNewLabel: addNewLabel,
        onInlineAdd: onInlineAdd,
        manageLabel: manageLabel,
        onManageTap: onManageTap,
        emptyLabel: emptyLabel,
      ),
      isScrollable: true,
      maxHeightFraction: 0.7,
    );
    if (selectedId != null) onSelected(selectedId);
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
                  valueLabel ?? placeholder ?? '',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: valueLabel == null ? AppColors.textHint : AppColors.textPrimary,
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

class _CascadingSelectSheet extends StatefulWidget {
  final List<AppCascadingSelectOption> options;
  final String? selectedLabel;
  final bool allowInlineAdd;
  final String addNewLabel;
  final Future<int?> Function(String name)? onInlineAdd;
  final String? manageLabel;
  final VoidCallback? onManageTap;
  final String? emptyLabel;

  const _CascadingSelectSheet({
    required this.options,
    this.selectedLabel,
    required this.allowInlineAdd,
    required this.addNewLabel,
    this.onInlineAdd,
    this.manageLabel,
    this.onManageTap,
    this.emptyLabel,
  });

  @override
  State<_CascadingSelectSheet> createState() => _CascadingSelectSheetState();
}

class _CascadingSelectSheetState extends State<_CascadingSelectSheet> {
  bool _isAdding = false;
  bool _isSubmitting = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitAdd() async {
    final name = _controller.text.trim();
    if (name.isEmpty || widget.onInlineAdd == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final newId = await widget.onInlineAdd!(name);
    if (!mounted) return;

    if (newId != null) {
      Navigator.of(context).pop(newId);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasOptions = widget.options.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasOptions)
            ...widget.options.map(
              (option) => ListTile(
                title: Text(option.label, style: AppTextStyles.bodyLarge),
                trailing: option.label == widget.selectedLabel
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(option.id),
              ),
            )
          else if (widget.emptyLabel != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Text(
                widget.emptyLabel!,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
          if (widget.manageLabel != null && widget.onManageTap != null) ...[
            Divider(height: 1.h, color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.tune_rounded, color: AppColors.primary),
              title: Text(widget.manageLabel!, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary)),
              onTap: () {
                Navigator.of(context).pop();
                widget.onManageTap!();
              },
            ),
          ],
          if (widget.allowInlineAdd) ...[
            Divider(height: 1.h, color: AppColors.divider),
            if (_isAdding)
              Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        enabled: !_isSubmitting,
                        style: AppTextStyles.bodyLarge,
                        decoration: InputDecoration(hintText: widget.addNewLabel, border: InputBorder.none),
                        onSubmitted: (_) => _submitAdd(),
                      ),
                    ),
                    _isSubmitting
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                            onPressed: _submitAdd,
                          ),
                  ],
                ),
              )
            else
              ListTile(
                leading: const Icon(Icons.add_rounded, color: AppColors.primary),
                title: Text(widget.addNewLabel, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary)),
                onTap: () => setState(() => _isAdding = true),
              ),
          ],
        ],
      ),
    );
  }
}

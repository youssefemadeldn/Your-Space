import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_input_label.dart';

class AppInput extends StatefulWidget {
  final String? label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool multiline;
  final bool enabled;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final TextDirection? textDirection;

  const AppInput({
    super.key,
    this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.multiline = false,
    this.enabled = true,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autovalidateMode,
    this.textDirection,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  FocusNode? _internalFocusNode;
  bool _hasFocus = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      maxLines: widget.multiline ? 3 : 1,
      minLines: widget.multiline ? 3 : 1,
      textAlignVertical:
          widget.multiline ? TextAlignVertical.top : TextAlignVertical.center,
      keyboardType:
          widget.multiline ? TextInputType.multiline : widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      textDirection: widget.textDirection,
      style: AppTextStyles.bodyLarge,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      decoration: InputDecoration(
        hintText: widget.hintText,
        errorText: widget.errorText,
        helperText: widget.helperText,
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        helperStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(
                widget.prefixIcon,
                size: 20.w,
                color: _hasFocus ? AppColors.primary : AppColors.textHint,
              ),
        suffixIcon: widget.suffixIcon,
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppInputLabel(widget.label!),
        SizedBox(height: 8.h),
        field,
      ],
    );
  }
}

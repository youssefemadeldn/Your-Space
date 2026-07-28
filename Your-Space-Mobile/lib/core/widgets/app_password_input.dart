import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import 'app_input.dart';

class AppPasswordInput extends StatefulWidget {
  final String? label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;

  const AppPasswordInput({
    super.key,
    this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<AppPasswordInput> createState() => _AppPasswordInputState();
}

class _AppPasswordInputState extends State<AppPasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppInput(
      label: widget.label,
      controller: widget.controller,
      focusNode: widget.focusNode,
      hintText: widget.hintText,
      errorText: widget.errorText,
      helperText: widget.helperText,
      enabled: widget.enabled,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          size: 20.w,
          color: AppColors.textHint,
        ),
        tooltip:
            (_obscureText ? 'common.showPassword' : 'common.hidePassword')
                .tr(),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      ),
    );
  }
}

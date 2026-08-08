import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';

/// Shared create/edit sheet content for all 3 classification management
/// screens — purely presentational (no cubit awareness); each concrete
/// screen wraps this in its own `BlocProvider.value`/`BlocBuilder` to supply
/// [submitting]/[errorText] and handle [onSubmit], mirroring `GroupFormSheet`.
class ClassificationFormSheet extends StatefulWidget {
  final String title;
  final String? initialName;
  final String namePlaceholder;
  final bool submitting;
  final String? errorText;
  final String saveLabel;
  final String cancelLabel;
  final ValueChanged<String> onSubmit;

  const ClassificationFormSheet({
    super.key,
    required this.title,
    this.initialName,
    required this.namePlaceholder,
    required this.submitting,
    this.errorText,
    required this.saveLabel,
    required this.cancelLabel,
    required this.onSubmit,
  });

  @override
  State<ClassificationFormSheet> createState() => _ClassificationFormSheetState();
}

class _ClassificationFormSheetState extends State<ClassificationFormSheet> {
  late final _nameController = TextEditingController(text: widget.initialName);
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = widget.namePlaceholder);
      return;
    }
    widget.onSubmit(name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          AppInput(
            controller: _nameController,
            hintText: widget.namePlaceholder,
            errorText: _nameError ?? widget.errorText,
            enabled: !widget.submitting,
            maxLength: 200,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: widget.cancelLabel,
                  variant: AppButtonVariant.secondary,
                  onPressed: widget.submitting ? null : () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AppButton(
                  label: widget.saveLabel,
                  loading: widget.submitting,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

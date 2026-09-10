import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_shadows.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';

/// Step 3's person-lookup combobox — an inline suggestion list below the
/// field (not a true floating overlay, a deliberate simplification of the
/// mockup's floating panel) shown on focus. Results come from a debounced
/// server-side search in `PersonWizardCubit` (via [onQueryChanged]) rather
/// than a client-side snapshot, so people beyond the first page are findable.
/// Free text that doesn't resolve to a pick is reverted on blur so the field
/// never implies a selection that was never saved. Wizard-only, screen-local.
class PersonSearchAutocomplete extends StatefulWidget {
  final List<Person> results;
  final bool loading;
  final String? initialName;
  final ValueChanged<String> onQueryChanged;
  final void Function(int id, String name) onSelected;
  final VoidCallback? onDismissed;

  const PersonSearchAutocomplete({
    super.key,
    required this.results,
    required this.loading,
    this.initialName,
    required this.onQueryChanged,
    required this.onSelected,
    this.onDismissed,
  });

  @override
  State<PersonSearchAutocomplete> createState() => _PersonSearchAutocompleteState();
}

class _PersonSearchAutocompleteState extends State<PersonSearchAutocomplete> {
  late final _controller = TextEditingController(text: widget.initialName);
  final _focusNode = FocusNode();
  bool _showSuggestions = false;
  late String? _lastSelectedName = widget.initialName;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() => _showSuggestions = true);
      widget.onQueryChanged(_controller.text.trim());
      return;
    }
    // Blur: drop any unresolved free text so the row never looks like it
    // holds a person it doesn't.
    if (_controller.text != (_lastSelectedName ?? '')) {
      _controller.text = _lastSelectedName ?? '';
    }
    setState(() => _showSuggestions = false);
    widget.onDismissed?.call();
  }

  void _select(Person person) {
    _controller.text = person.name;
    _lastSelectedName = person.name;
    widget.onSelected(person.id, person.name);
    setState(() => _showSuggestions = false);
    _focusNode.unfocus();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    final first = parts.first.substring(0, 1);
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1].substring(0, 1) : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput(
          controller: _controller,
          focusNode: _focusNode,
          hintText: 'people.wizard.step3.searchHint'.tr(),
          prefixIcon: Icons.search_rounded,
          onChanged: (value) => widget.onQueryChanged(value.trim()),
        ),
        if (_showSuggestions)
          Container(
            margin: EdgeInsets.only(top: 4.h),
            constraints: BoxConstraints(maxHeight: 220.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: AppShadows.soft,
            ),
            child: _buildPanelBody(),
          ),
      ],
    );
  }

  Widget _buildPanelBody() {
    if (widget.loading) {
      return Padding(
        padding: EdgeInsets.all(14.w),
        child: Center(
          child: SizedBox(
            width: 20.w,
            height: 20.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (widget.results.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(14.w),
        child: Text(
          'people.wizard.step3.noMatches'.tr(),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.results.length,
      itemBuilder: (context, index) {
        final person = widget.results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.brandRedSoft,
            child: Text(
              _initials(person.name),
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
            ),
          ),
          title: Text(person.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(
            person.groupName,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          onTap: () => _select(person),
        );
      },
    );
  }
}

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
/// mockup's floating panel) shown on focus, up to 6 matches, filtered
/// client-side by substring against the wizard's already-fetched people
/// snapshot (unrestricted across the user's People, per the locked spec).
/// Wizard-only, screen-local — not shared across 2+ screens.
class PersonSearchAutocomplete extends StatefulWidget {
  final List<Person> people;
  final String? initialName;
  final void Function(int id, String name) onSelected;

  const PersonSearchAutocomplete({
    super.key,
    required this.people,
    this.initialName,
    required this.onSelected,
  });

  @override
  State<PersonSearchAutocomplete> createState() => _PersonSearchAutocompleteState();
}

class _PersonSearchAutocompleteState extends State<PersonSearchAutocomplete> {
  late final _controller = TextEditingController(text: widget.initialName);
  final _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _showSuggestions = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Person> get _filtered {
    final query = _controller.text.trim().toLowerCase();
    final matches = query.isEmpty
        ? widget.people
        : widget.people.where((p) => p.name.toLowerCase().contains(query)).toList();
    return matches.take(6).toList();
  }

  void _select(Person person) {
    _controller.text = person.name;
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
          onChanged: (_) => setState(() {}),
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
            child: _filtered.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(14.w),
                    child: Text(
                      'people.wizard.step3.noMatches'.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final person = _filtered[index];
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
                  ),
          ),
      ],
    );
  }
}

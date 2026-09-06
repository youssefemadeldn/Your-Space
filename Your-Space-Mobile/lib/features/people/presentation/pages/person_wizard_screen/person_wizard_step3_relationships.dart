import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_cascading_select.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/draft_relationship_row.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/person_wizard_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/person_wizard_state.dart';

import 'person_search_autocomplete.dart';

class PersonWizardStep3Relationships extends StatelessWidget {
  const PersonWizardStep3Relationships({super.key});

  static String _relationLabel(RelationType type) => type.labelKey.tr();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonWizardCubit, PersonWizardState>(
      builder: (context, state) {
        if (state is! PersonWizardReady) return const SizedBox.shrink();
        final cubit = context.read<PersonWizardCubit>();

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'people.wizard.step3.sectionTitle'.tr(),
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: 10.h),
              for (var i = 0; i < state.relationshipRows.length; i++) ...[
                _RelationshipRowCard(
                  index: i,
                  row: state.relationshipRows[i],
                  peopleForLookup: state.peopleForLookup,
                  onRemove: () => cubit.removeRelationshipRow(state.relationshipRows[i].localId),
                  onTypeChanged: (type) => cubit.updateRelationshipType(state.relationshipRows[i].localId, type),
                  onPersonSelected: (id, name) =>
                      cubit.updateRelationshipPerson(state.relationshipRows[i].localId, id, name),
                ),
                SizedBox(height: 12.h),
              ],
              InkWell(
                onTap: cubit.addRelationshipRow,
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: AppColors.primary, size: 20.w),
                      SizedBox(width: 6.w),
                      Text(
                        'people.wizard.step3.addFamilyMember'.tr(),
                        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RelationshipRowCard extends StatelessWidget {
  final int index;
  final DraftRelationshipRow row;
  final List<Person> peopleForLookup;
  final VoidCallback onRemove;
  final ValueChanged<RelationType> onTypeChanged;
  final void Function(int id, String name) onPersonSelected;

  const _RelationshipRowCard({
    required this.index,
    required this.row,
    required this.peopleForLookup,
    required this.onRemove,
    required this.onTypeChanged,
    required this.onPersonSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(20.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'people.wizard.step3.familyMember'.tr(namedArgs: {'index': '${index + 1}'}),
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, letterSpacing: 0.4),
              ),
              InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(6.w),
                  child: Icon(Icons.close_rounded, size: 18.w, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          AppCascadingSelect(
            valueLabel: row.relationType == null ? null : PersonWizardStep3Relationships._relationLabel(row.relationType!),
            placeholder: 'people.wizard.step3.relationTypePlaceholder'.tr(),
            options: RelationType.values
                .map((t) => AppCascadingSelectOption(id: t.index, label: PersonWizardStep3Relationships._relationLabel(t)))
                .toList(),
            onSelected: (index) => onTypeChanged(RelationType.values[index]),
          ),
          SizedBox(height: 10.h),
          PersonSearchAutocomplete(
            people: peopleForLookup,
            initialName: row.relatedPersonName,
            onSelected: onPersonSelected,
          ),
        ],
      ),
    );
  }
}

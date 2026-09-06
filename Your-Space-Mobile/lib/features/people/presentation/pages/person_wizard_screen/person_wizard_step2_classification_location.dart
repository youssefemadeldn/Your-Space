import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/entities/classification_entity_kind.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/classification_management_args.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_cascading_select.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/person_wizard_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/person_wizard_state.dart';

class PersonWizardStep2ClassificationLocation extends StatelessWidget {
  const PersonWizardStep2ClassificationLocation({super.key});

  String? _nameFor(int? id, List<({int id, String name})> options) {
    if (id == null) return null;
    for (final option in options) {
      if (option.id == id) return option.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonWizardCubit, PersonWizardState>(
      builder: (context, state) {
        if (state is! PersonWizardReady) return const SizedBox.shrink();
        final cubit = context.read<PersonWizardCubit>();

        final groupOptions = state.availableGroups.map((g) => (id: g.id, name: g.name)).toList();
        final subGroupOptions = state.availableSubGroups.map((s) => (id: s.id, name: s.name)).toList();
        final governorateOptions = state.availableGovernorates.map((g) => (id: g.id, name: g.name)).toList();
        final cityOptions = state.availableCities.map((c) => (id: c.id, name: c.name)).toList();
        final neighborhoodOptions = state.availableNeighborhoods.map((n) => (id: n.id, name: n.name)).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('people.wizard.step2.classificationSection'.tr(), style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
              SizedBox(height: 10.h),
              AppCascadingSelect(
                label: 'people.wizard.step2.groupLabel'.tr(),
                valueLabel: _nameFor(state.groupId, groupOptions),
                placeholder: 'people.wizard.step2.groupPlaceholder'.tr(),
                options: groupOptions.map((o) => AppCascadingSelectOption(id: o.id, label: o.name)).toList(),
                onSelected: cubit.selectGroup,
              ),
              SizedBox(height: 14.h),
              AppCascadingSelect(
                label: 'people.wizard.step2.subGroupLabel'.tr(),
                valueLabel: _nameFor(state.subGroupId, subGroupOptions),
                placeholder: state.groupId == null
                    ? 'people.wizard.step2.pickGroupFirst'.tr()
                    : 'people.wizard.step2.subGroupPlaceholder'.tr(),
                enabled: state.groupId != null,
                options: subGroupOptions.map((o) => AppCascadingSelectOption(id: o.id, label: o.name)).toList(),
                onSelected: cubit.selectSubGroup,
                allowInlineAdd: true,
                addNewLabel: 'people.wizard.step2.addSubGroup'.tr(),
                onInlineAdd: cubit.addSubGroupInline,
                emptyLabel: 'people.wizard.step2.noSubGroups'.tr(),
                manageLabel: state.groupId == null ? null : 'people.wizard.step2.manageSubGroups'.tr(),
                onManageTap: state.groupId == null
                    ? null
                    : () => context.pushNamed(
                          AppRoutes.classificationManagement,
                          extra: ClassificationManagementArgs(
                            kind: ClassificationEntityKind.subgroup,
                            parentId: state.groupId!,
                            parentName: _nameFor(state.groupId, groupOptions) ?? '',
                          ),
                        ),
              ),
              SizedBox(height: 24.h),
              Text('people.wizard.step2.locationSection'.tr(), style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
              SizedBox(height: 10.h),
              AppCascadingSelect(
                label: 'people.wizard.step2.governorateLabel'.tr(),
                valueLabel: _nameFor(state.governorateId, governorateOptions),
                placeholder: 'people.wizard.step2.governoratePlaceholder'.tr(),
                options:
                    governorateOptions.map((o) => AppCascadingSelectOption(id: o.id, label: o.name)).toList(),
                onSelected: cubit.selectGovernorate,
                allowInlineAdd: true,
                addNewLabel: 'people.wizard.step2.addGovernorate'.tr(),
                onInlineAdd: cubit.addGovernorateInline,
              ),
              SizedBox(height: 14.h),
              AppCascadingSelect(
                label: 'people.wizard.step2.cityLabel'.tr(),
                valueLabel: _nameFor(state.cityId, cityOptions),
                placeholder: state.governorateId == null
                    ? 'people.wizard.step2.pickGovernorateFirst'.tr()
                    : 'people.wizard.step2.cityPlaceholder'.tr(),
                enabled: state.governorateId != null,
                options: cityOptions.map((o) => AppCascadingSelectOption(id: o.id, label: o.name)).toList(),
                onSelected: cubit.selectCity,
                allowInlineAdd: true,
                addNewLabel: 'people.wizard.step2.addCity'.tr(),
                onInlineAdd: cubit.addCityInline,
                emptyLabel: 'people.wizard.step2.noCities'.tr(),
                manageLabel: state.governorateId == null ? null : 'people.wizard.step2.manageCities'.tr(),
                onManageTap: state.governorateId == null
                    ? null
                    : () => context.pushNamed(
                          AppRoutes.classificationManagement,
                          extra: ClassificationManagementArgs(
                            kind: ClassificationEntityKind.city,
                            parentId: state.governorateId!,
                            parentName: _nameFor(state.governorateId, governorateOptions) ?? '',
                          ),
                        ),
              ),
              SizedBox(height: 14.h),
              AppCascadingSelect(
                label: 'people.wizard.step2.neighborhoodLabel'.tr(),
                valueLabel: _nameFor(state.neighborhoodId, neighborhoodOptions),
                placeholder: state.cityId == null
                    ? 'people.wizard.step2.pickCityFirst'.tr()
                    : 'people.wizard.step2.neighborhoodPlaceholder'.tr(),
                enabled: state.cityId != null,
                options:
                    neighborhoodOptions.map((o) => AppCascadingSelectOption(id: o.id, label: o.name)).toList(),
                onSelected: cubit.selectNeighborhood,
                allowInlineAdd: true,
                addNewLabel: 'people.wizard.step2.addNeighborhood'.tr(),
                onInlineAdd: cubit.addNeighborhoodInline,
                emptyLabel: 'people.wizard.step2.noNeighborhoods'.tr(),
                manageLabel: state.cityId == null ? null : 'people.wizard.step2.manageNeighborhoods'.tr(),
                onManageTap: state.cityId == null
                    ? null
                    : () => context.pushNamed(
                          AppRoutes.classificationManagement,
                          extra: ClassificationManagementArgs(
                            kind: ClassificationEntityKind.neighborhood,
                            parentId: state.cityId!,
                            parentName: _nameFor(state.cityId, cityOptions) ?? '',
                          ),
                        ),
              ),
              SizedBox(height: 8.h),
              Text(
                'people.wizard.step2.locationHint'.tr(),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

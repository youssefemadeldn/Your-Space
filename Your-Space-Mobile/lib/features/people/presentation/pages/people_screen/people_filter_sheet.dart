import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/helpers/bottom_sheet_helper.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_cascading_select.dart';
import 'package:your_space_mobile/core/widgets/app_chip.dart';

import '../../cubit/people_list_cubit/people_list_cubit.dart';
import '../../cubit/people_list_cubit/people_list_state.dart';

/// Subgroup + location filters. The group filter itself stays on the
/// always-visible chip row on the list body (unchanged) — this sheet layers
/// the 4 finer-grained dimensions on top of it.
class PeopleFilterSheet extends StatelessWidget {
  const PeopleFilterSheet({super.key});

  /// A modal bottom sheet is a sibling route of the page in the Navigator's
  /// overlay, not a descendant of the page-level `BlocProvider` — so the
  /// already-resolved cubit instance must be explicitly re-provided into it.
  static Future<void> open(BuildContext context) {
    final cubit = context.read<PeopleListCubit>();
    return BottomSheetHelper.showAppBottomSheet(
      context,
      BlocProvider.value(value: cubit, child: const PeopleFilterSheet()),
      isScrollable: true,
      maxHeightFraction: 0.8,
    );
  }

  String? _nameFor(int? id, List<({int id, String name})> options) {
    if (id == null) return null;
    for (final option in options) {
      if (option.id == id) return option.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PeopleListCubit, PeopleListState>(
      builder: (context, state) {
        if (state is! PeopleListSuccess) return const SizedBox.shrink();
        final cubit = context.read<PeopleListCubit>();
        final hasSubGroupOrLocationFilter = state.selectedSubGroupId != null ||
            state.selectedGovernorateId != null ||
            state.selectedCityId != null ||
            state.selectedNeighborhoodId != null;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('people.filters.title'.tr(), style: AppTextStyles.titleLarge),
                    TextButton(
                      onPressed: hasSubGroupOrLocationFilter ? cubit.clearSubGroupAndLocationFilters : null,
                      child: Text('people.filters.clearAll'.tr()),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'people.filters.subGroupLabel'.tr(),
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: 8.h),
                if (state.selectedGroupId == null)
                  Text(
                    'people.filters.pickGroupFirst'.tr(),
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  )
                else if (state.subGroups.isEmpty)
                  Text(
                    'people.filters.noSubGroups'.tr(),
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  )
                else
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      for (final subGroup in state.subGroups)
                        AppChip(
                          label: subGroup.name,
                          selected: state.selectedSubGroupId == subGroup.id,
                          onTap: () => cubit.filterBySubGroup(
                            state.selectedSubGroupId == subGroup.id ? null : subGroup.id,
                          ),
                        ),
                    ],
                  ),
                SizedBox(height: 20.h),
                Text(
                  'people.filters.locationLabel'.tr(),
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: 8.h),
                AppCascadingSelect(
                  label: 'people.filters.governorateLabel'.tr(),
                  valueLabel: _nameFor(
                    state.selectedGovernorateId,
                    state.governorates.map((g) => (id: g.id, name: g.name)).toList(),
                  ),
                  placeholder: 'people.filters.allGovernorates'.tr(),
                  options: state.governorates.map((g) => AppCascadingSelectOption(id: g.id, label: g.name)).toList(),
                  onSelected: cubit.filterByGovernorate,
                ),
                SizedBox(height: 14.h),
                AppCascadingSelect(
                  label: 'people.filters.cityLabel'.tr(),
                  valueLabel:
                      _nameFor(state.selectedCityId, state.cities.map((c) => (id: c.id, name: c.name)).toList()),
                  placeholder: state.selectedGovernorateId == null
                      ? 'people.filters.pickGovernorateFirst'.tr()
                      : 'people.filters.allCities'.tr(),
                  enabled: state.selectedGovernorateId != null,
                  options: state.cities.map((c) => AppCascadingSelectOption(id: c.id, label: c.name)).toList(),
                  onSelected: cubit.filterByCity,
                  emptyLabel: 'people.filters.noCities'.tr(),
                ),
                SizedBox(height: 14.h),
                AppCascadingSelect(
                  label: 'people.filters.neighborhoodLabel'.tr(),
                  valueLabel: _nameFor(
                    state.selectedNeighborhoodId,
                    state.neighborhoods.map((n) => (id: n.id, name: n.name)).toList(),
                  ),
                  placeholder: state.selectedCityId == null
                      ? 'people.filters.pickCityFirst'.tr()
                      : 'people.filters.allNeighborhoods'.tr(),
                  enabled: state.selectedCityId != null,
                  options:
                      state.neighborhoods.map((n) => AppCascadingSelectOption(id: n.id, label: n.name)).toList(),
                  onSelected: cubit.filterByNeighborhood,
                  emptyLabel: 'people.filters.noNeighborhoods'.tr(),
                ),
                SizedBox(height: 20.h),
                AppButton(label: 'common.done'.tr(), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        );
      },
    );
  }
}

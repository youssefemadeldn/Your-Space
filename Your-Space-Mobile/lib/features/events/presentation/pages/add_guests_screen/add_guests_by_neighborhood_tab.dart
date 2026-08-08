import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/widgets/app_chip.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';

import '../../cubit/add_guests_action_cubit/add_guests_action_cubit.dart';
import '../../cubit/add_guests_action_cubit/add_guests_action_state.dart';
import '../../cubit/add_guests_list_cubit/add_guests_list_cubit.dart';
import '../../cubit/add_guests_list_cubit/add_guests_list_state.dart';
import 'add_guests_entity_row.dart';

/// Neighborhood is scoped to a parent City, which is itself scoped to a
/// parent Governorate — this tab cascades Governorate chip → City chip
/// (reusing the same `cityOptions`/`loadCitiesForGovernorate` the City tab
/// uses, since only one tab is mounted at a time) → Neighborhood list.
class AddGuestsByNeighborhoodTab extends StatefulWidget {
  final AddGuestsListSuccess state;
  final int eventId;

  const AddGuestsByNeighborhoodTab({super.key, required this.state, required this.eventId});

  @override
  State<AddGuestsByNeighborhoodTab> createState() => _AddGuestsByNeighborhoodTabState();
}

class _AddGuestsByNeighborhoodTabState extends State<AddGuestsByNeighborhoodTab> {
  int? _selectedGovernorateId;
  int? _selectedCityId;

  void _selectGovernorate(int governorateId) {
    setState(() {
      _selectedGovernorateId = governorateId;
      _selectedCityId = null;
    });
    context.read<AddGuestsListCubit>().loadCitiesForGovernorate(governorateId);
  }

  void _selectCity(int cityId) {
    setState(() => _selectedCityId = cityId);
    context.read<AddGuestsListCubit>().loadNeighborhoodsForCity(cityId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.governorates.isEmpty) {
      return EmptyStateWidget(icon: Icons.map_outlined, title: 'people.wizard.step2.governoratePlaceholder'.tr());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40.h,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            children: [
              for (final governorate in widget.state.governorates)
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 8.w),
                  child: AppChip(
                    label: governorate.name,
                    selected: _selectedGovernorateId == governorate.id,
                    onTap: () => _selectGovernorate(governorate.id),
                  ),
                ),
            ],
          ),
        ),
        if (_selectedGovernorateId != null) ...[
          SizedBox(height: 8.h),
          SizedBox(
            height: 40.h,
            child: widget.state.cityOptions.isEmpty
                ? Padding(
                    padding: EdgeInsetsDirectional.only(start: 16.w),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('people.filters.noCities'.tr()),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final city in widget.state.cityOptions)
                        Padding(
                          padding: EdgeInsetsDirectional.only(end: 8.w),
                          child: AppChip(
                            label: city.name,
                            selected: _selectedCityId == city.id,
                            onTap: () => _selectCity(city.id),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
        SizedBox(height: 8.h),
        Expanded(
          child: _selectedCityId == null
              ? EmptyStateWidget(
                  icon: Icons.holiday_village_outlined,
                  title: 'people.wizard.step2.pickCityFirst'.tr(),
                )
              : widget.state.neighborhoodOptions.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.holiday_village_outlined,
                      title: 'people.filters.noNeighborhoods'.tr(),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: widget.state.neighborhoodOptions.length,
                      itemBuilder: (context, index) {
                        final neighborhood = widget.state.neighborhoodOptions[index];
                        return BlocBuilder<AddGuestsActionCubit, AddGuestsActionState>(
                          builder: (context, actionState) => AddGuestsEntityRow(
                            name: neighborhood.name,
                            personCount: neighborhood.personCount,
                            submitting: actionState is AddGuestsActionSubmitting &&
                                actionState.neighborhoodId == neighborhood.id,
                            onAdd: neighborhood.personCount == 0
                                ? null
                                : () => context
                                    .read<AddGuestsActionCubit>()
                                    .addNeighborhood(eventId: widget.eventId, neighborhoodId: neighborhood.id),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

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

/// City is scoped to a parent Governorate (no flat "all my cities" endpoint)
/// — this tab picks a governorate chip first, then lists that governorate's
/// cities.
class AddGuestsByCityTab extends StatefulWidget {
  final AddGuestsListSuccess state;
  final int eventId;

  const AddGuestsByCityTab({super.key, required this.state, required this.eventId});

  @override
  State<AddGuestsByCityTab> createState() => _AddGuestsByCityTabState();
}

class _AddGuestsByCityTabState extends State<AddGuestsByCityTab> {
  int? _selectedGovernorateId;

  void _selectGovernorate(int governorateId) {
    setState(() => _selectedGovernorateId = governorateId);
    context.read<AddGuestsListCubit>().loadCitiesForGovernorate(governorateId);
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
        SizedBox(height: 8.h),
        Expanded(
          child: _selectedGovernorateId == null
              ? EmptyStateWidget(
                  icon: Icons.location_city_outlined,
                  title: 'people.wizard.step2.pickGovernorateFirst'.tr(),
                )
              : widget.state.cityOptions.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.location_city_outlined,
                      title: 'people.filters.noCities'.tr(),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: widget.state.cityOptions.length,
                      itemBuilder: (context, index) {
                        final city = widget.state.cityOptions[index];
                        return BlocBuilder<AddGuestsActionCubit, AddGuestsActionState>(
                          builder: (context, actionState) => AddGuestsEntityRow(
                            name: city.name,
                            personCount: city.personCount,
                            submitting: actionState is AddGuestsActionSubmitting && actionState.cityId == city.id,
                            onAdd: city.personCount == 0
                                ? null
                                : () => context
                                    .read<AddGuestsActionCubit>()
                                    .addCity(eventId: widget.eventId, cityId: city.id),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

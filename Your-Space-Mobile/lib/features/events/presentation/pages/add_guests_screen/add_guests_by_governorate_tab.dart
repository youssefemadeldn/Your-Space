import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';

import '../../cubit/add_guests_action_cubit/add_guests_action_cubit.dart';
import '../../cubit/add_guests_action_cubit/add_guests_action_state.dart';
import '../../cubit/add_guests_list_cubit/add_guests_list_state.dart';
import 'add_guests_entity_row.dart';

/// Flat list — Governorate has a flat `/governorates` endpoint (global +
/// user rows), so unlike City/Neighborhood/Subgroup it needs no parent
/// picker. Structural twin of `AddGuestsByGroupTab`.
class AddGuestsByGovernorateTab extends StatelessWidget {
  final AddGuestsListSuccess state;
  final int eventId;

  const AddGuestsByGovernorateTab({super.key, required this.state, required this.eventId});

  @override
  Widget build(BuildContext context) {
    if (state.governorates.isEmpty) {
      return EmptyStateWidget(icon: Icons.map_outlined, title: 'people.wizard.step2.governoratePlaceholder'.tr());
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: state.governorates.length,
      itemBuilder: (context, index) {
        final governorate = state.governorates[index];
        return BlocBuilder<AddGuestsActionCubit, AddGuestsActionState>(
          builder: (context, actionState) => AddGuestsEntityRow(
            name: governorate.name,
            personCount: governorate.personCount,
            submitting: actionState is AddGuestsActionSubmitting && actionState.governorateId == governorate.id,
            onAdd: governorate.personCount == 0
                ? null
                : () => context
                    .read<AddGuestsActionCubit>()
                    .addGovernorate(eventId: eventId, governorateId: governorate.id),
          ),
        );
      },
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';

import '../../cubit/add_guests_action_cubit/add_guests_action_cubit.dart';
import '../../cubit/add_guests_action_cubit/add_guests_action_state.dart';
import '../../cubit/add_guests_list_cubit/add_guests_list_state.dart';

class AddGuestsByGroupTab extends StatelessWidget {
  final AddGuestsListSuccess state;
  final int eventId;

  const AddGuestsByGroupTab({super.key, required this.state, required this.eventId});

  @override
  Widget build(BuildContext context) {
    if (state.groups.isEmpty) {
      return EmptyStateWidget(icon: Icons.groups_rounded, title: 'groups.list.emptyTitle'.tr());
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: state.groups.length,
      itemBuilder: (context, index) {
        final group = state.groups[index];
        final count = state.availableCountForGroup(group.id);
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        'events.addGuests.groupPeopleCount'.tr(namedArgs: {'count': '$count'}),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                BlocBuilder<AddGuestsActionCubit, AddGuestsActionState>(
                  builder: (context, actionState) => AppButton(
                    label: 'events.addGuests.addGroupCta'.tr(),
                    variant: AppButtonVariant.soft,
                    size: AppButtonSize.sm,
                    loading: actionState is AddGuestsActionSubmitting,
                    onPressed: count == 0
                        ? null
                        : () => context
                            .read<AddGuestsActionCubit>()
                            .addGroup(eventId: eventId, groupId: group.id),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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

/// Subgroup is scoped to a parent Group (no flat "all my subgroups" endpoint,
/// mirroring the Person wizard's own Group→Subgroup cascade) — this tab picks
/// a group chip first, reusing [AddGuestsListSuccess.groupProgress] for the
/// picker options, then lists that group's subgroups.
class AddGuestsBySubGroupTab extends StatefulWidget {
  final AddGuestsListSuccess state;
  final int eventId;

  const AddGuestsBySubGroupTab({super.key, required this.state, required this.eventId});

  @override
  State<AddGuestsBySubGroupTab> createState() => _AddGuestsBySubGroupTabState();
}

class _AddGuestsBySubGroupTabState extends State<AddGuestsBySubGroupTab> {
  int? _selectedGroupId;

  void _selectGroup(int groupId) {
    setState(() => _selectedGroupId = groupId);
    context.read<AddGuestsListCubit>().loadSubGroupsForGroup(groupId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.groupProgress.isEmpty) {
      return EmptyStateWidget(icon: Icons.groups_rounded, title: 'groups.list.emptyTitle'.tr());
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
              for (final progress in widget.state.groupProgress)
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 8.w),
                  child: AppChip(
                    label: progress.groupName,
                    selected: _selectedGroupId == progress.groupId,
                    onTap: () => _selectGroup(progress.groupId),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Expanded(
          child: _selectedGroupId == null
              ? EmptyStateWidget(
                  icon: Icons.account_tree_outlined,
                  title: 'people.wizard.step2.pickGroupFirst'.tr(),
                )
              : widget.state.subGroupOptions.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.account_tree_outlined,
                      title: 'people.filters.noSubGroups'.tr(),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: widget.state.subGroupOptions.length,
                      itemBuilder: (context, index) {
                        final subGroup = widget.state.subGroupOptions[index];
                        return BlocBuilder<AddGuestsActionCubit, AddGuestsActionState>(
                          builder: (context, actionState) => AddGuestsEntityRow(
                            name: subGroup.name,
                            personCount: subGroup.personCount,
                            submitting:
                                actionState is AddGuestsActionSubmitting && actionState.subGroupId == subGroup.id,
                            onAdd: subGroup.personCount == 0
                                ? null
                                : () => context
                                    .read<AddGuestsActionCubit>()
                                    .addSubGroup(eventId: widget.eventId, subGroupId: subGroup.id),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

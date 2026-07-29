import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/mock/entities/group.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_list_tile.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';

import '../../cubit/groups_list_cubit/groups_list_cubit.dart';
import 'group_form_sheet.dart';

class GroupsListBody extends StatelessWidget {
  final List<Group> groups;

  const GroupsListBody({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            hintText: 'groups.list.searchHint'.tr(),
            prefixIcon: Icons.search_rounded,
            onChanged: (value) => context.read<GroupsListCubit>().search(value),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: groups.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.groups_rounded,
                    title: 'groups.list.emptyTitle'.tr(),
                    actionLabel: 'groups.list.emptyAction'.tr(),
                    onAction: () => GroupFormSheet.open(context),
                  )
                : SingleChildScrollView(
                    child: AppCard(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Column(
                        children: [
                          for (var i = 0; i < groups.length; i++)
                            AppListTile(
                              avatarName: groups[i].name,
                              title: groups[i].name,
                              trailing:
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                              divider: i != groups.length - 1,
                              onTap: () => GroupFormSheet.open(context, group: groups[i]),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

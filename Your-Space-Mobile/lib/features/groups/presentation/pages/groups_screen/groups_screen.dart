import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_bottom_nav.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';

import '../../cubit/group_action_cubit/group_action_cubit.dart';
import '../../cubit/group_action_cubit/group_action_state.dart';
import '../../cubit/groups_list_cubit/groups_list_cubit.dart';
import '../../cubit/groups_list_cubit/groups_list_state.dart';
import 'group_form_sheet.dart';
import 'groups_list_body.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: 'groups.list.title'.tr()),
      body: SafeArea(
        child: BlocListener<GroupActionCubit, GroupActionState>(
          listener: (context, state) {
            if (state is GroupActionSuccess) {
              Navigator.of(context).pop();
              context.read<GroupsListCubit>().load();
              getIt<SnackBarHelper>().showSuccess('groups.savedMessage'.tr());
            }
          },
          child: BlocBuilder<GroupsListCubit, GroupsListState>(
            builder: (context, state) => switch (state) {
              GroupsListSuccess(:final groups) => GroupsListBody(groups: groups),
              GroupsListError(:final message) => ErrorStateWidget(
                  message: message,
                  onRetry: () => context.read<GroupsListCubit>().load(),
                ),
              _ => const AppLoadingIndicator(),
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => GroupFormSheet.open(context),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

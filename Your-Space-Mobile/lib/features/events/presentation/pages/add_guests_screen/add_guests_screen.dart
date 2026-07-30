import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/args/add_guests_args.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/app_tabs.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';

import '../../cubit/add_guests_action_cubit/add_guests_action_cubit.dart';
import '../../cubit/add_guests_action_cubit/add_guests_action_state.dart';
import '../../cubit/add_guests_list_cubit/add_guests_list_cubit.dart';
import '../../cubit/add_guests_list_cubit/add_guests_list_state.dart';
import 'add_guests_by_group_tab.dart';
import 'add_guests_people_tab.dart';

class AddGuestsScreen extends StatefulWidget {
  final AddGuestsArgs args;

  const AddGuestsScreen({super.key, required this.args});

  @override
  State<AddGuestsScreen> createState() => _AddGuestsScreenState();
}

class _AddGuestsScreenState extends State<AddGuestsScreen> {
  int _tabIndex = 0;
  final Set<int> _selectedPersonIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'events.addGuests.title'.tr(namedArgs: {'eventName': widget.args.eventName}),
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: BlocListener<AddGuestsActionCubit, AddGuestsActionState>(
          listener: (context, state) {
            if (state is AddGuestsActionSuccess) {
              getIt<SnackBarHelper>().showSuccess(
                'events.addGuests.resultMessage'.tr(namedArgs: {
                  'added': '${state.result.addedCount}',
                  'alreadyPresent': '${state.result.alreadyPresentCount}',
                }),
              );
              setState(() => _selectedPersonIds.clear());
              context.read<AddGuestsListCubit>().load(widget.args.eventId);
            } else if (state is AddGuestsActionError) {
              getIt<SnackBarHelper>().showError(state.message);
            }
          },
          child: BlocBuilder<AddGuestsListCubit, AddGuestsListState>(
            builder: (context, state) => switch (state) {
              AddGuestsListSuccess() => Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: AppTabs(
                        tabs: ['events.addGuests.peopleTab'.tr(), 'events.addGuests.byGroupTab'.tr()],
                        activeIndex: _tabIndex,
                        onChanged: (index) => setState(() => _tabIndex = index),
                      ),
                    ),
                    Expanded(
                      child: _tabIndex == 0
                          ? AddGuestsPeopleTab(
                              state: state,
                              selectedPersonIds: _selectedPersonIds,
                              onToggle: (id) => setState(() {
                                if (!_selectedPersonIds.remove(id)) _selectedPersonIds.add(id);
                              }),
                            )
                          : AddGuestsByGroupTab(state: state, eventId: widget.args.eventId),
                    ),
                  ],
                ),
              AddGuestsListError(:final message) => ErrorStateWidget(
                  message: message,
                  onRetry: () => context.read<AddGuestsListCubit>().load(widget.args.eventId),
                ),
              _ => const AppLoadingIndicator(),
            },
          ),
        ),
      ),
      bottomNavigationBar: _tabIndex == 0
          ? SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: BlocBuilder<AddGuestsActionCubit, AddGuestsActionState>(
                  builder: (context, state) => AppButton(
                    label: 'events.addGuests.addNPeople'
                        .tr(namedArgs: {'count': '${_selectedPersonIds.length}'}),
                    fullWidth: true,
                    loading: state is AddGuestsActionSubmitting,
                    onPressed: _selectedPersonIds.isEmpty
                        ? null
                        : () => context.read<AddGuestsActionCubit>().addPersons(
                              eventId: widget.args.eventId,
                              personIds: _selectedPersonIds.toList(),
                            ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/router/args/event_guests_args.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';

import '../../cubit/event_guest_action_cubit/event_guest_action_cubit.dart';
import '../../cubit/event_guest_action_cubit/event_guest_action_state.dart';
import '../../cubit/event_guests_list_cubit/event_guests_list_cubit.dart';
import '../../cubit/event_guests_list_cubit/event_guests_list_state.dart';
import 'event_guests_body.dart';

class EventGuestsScreen extends StatelessWidget {
  final EventGuestsArgs args;

  const EventGuestsScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: 'events.guests.title'.tr(), onBack: () => context.pop()),
      body: SafeArea(
        child: BlocListener<EventGuestActionCubit, EventGuestActionState>(
          listener: (context, state) {
            if (state is EventGuestActionSuccess) {
              context.read<EventGuestsListCubit>().reloadAfterAction();
            }
          },
          child: BlocBuilder<EventGuestsListCubit, EventGuestsListState>(
            builder: (context, state) => switch (state) {
              EventGuestsListSuccess(
                :final guests,
                :final groups,
                :final selectedStatus,
                :final selectedGroupId
              ) =>
                EventGuestsBody(
                  eventId: args.eventId,
                  guests: guests,
                  groups: groups,
                  selectedStatus: selectedStatus,
                  selectedGroupId: selectedGroupId,
                ),
              EventGuestsListError(:final message) => ErrorStateWidget(
                  message: message,
                  onRetry: () => context.read<EventGuestsListCubit>().load(args.eventId),
                ),
              _ => const AppLoadingIndicator(),
            },
          ),
        ),
      ),
    );
  }
}

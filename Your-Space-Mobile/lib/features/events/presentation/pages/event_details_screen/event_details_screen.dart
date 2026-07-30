import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/event_details_args.dart';
import 'package:your_space_mobile/core/router/args/event_form_args.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';

import '../../cubit/event_details_cubit/event_details_cubit.dart';
import '../../cubit/event_details_cubit/event_details_state.dart';
import 'event_details_body.dart';

class EventDetailsScreen extends StatelessWidget {
  final EventDetailsArgs args;

  const EventDetailsScreen({super.key, required this.args});

  Future<void> _editEvent(BuildContext context) async {
    await context.pushNamed(AppRoutes.eventForm, extra: EventFormArgs(eventId: args.eventId));
    if (!context.mounted) return;
    context.read<EventDetailsCubit>().loadDetails(args.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventDetailsCubit, EventDetailsState>(
      builder: (context, state) {
        final title = state is EventDetailsSuccess ? state.event.name : args.eventName;
        return Scaffold(
          appBar: AppAppBar(
            title: title,
            onBack: () => context.pop(),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'common.edit'.tr(),
              onPressed: () => _editEvent(context),
            ),
          ),
          body: SafeArea(
            child: switch (state) {
              EventDetailsSuccess(:final event, :final progress) =>
                EventDetailsBody(event: event, progress: progress),
              EventDetailsError(:final message) => ErrorStateWidget(
                  message: message,
                  onRetry: () => context.read<EventDetailsCubit>().loadDetails(args.eventId),
                ),
              _ => const AppLoadingIndicator(),
            },
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/router/args/event_details_args.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';

import '../../cubit/event_details_cubit/event_details_cubit.dart';
import '../../cubit/event_details_cubit/event_details_state.dart';
import 'event_details_body.dart';

class EventDetailsScreen extends StatelessWidget {
  final EventDetailsArgs args;

  const EventDetailsScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: args.eventName, onBack: () => context.pop()),
      body: SafeArea(
        child: BlocBuilder<EventDetailsCubit, EventDetailsState>(
          builder: (context, state) => switch (state) {
            EventDetailsSuccess(:final event, :final progress) =>
              EventDetailsBody(event: event, progress: progress),
            EventDetailsError(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context.read<EventDetailsCubit>().loadDetails(args.eventId),
              ),
            _ => const AppLoadingIndicator(),
          },
        ),
      ),
    );
  }
}

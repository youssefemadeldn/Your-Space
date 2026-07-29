import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/helpers/date_formatter_helper.dart';
import 'package:your_space_mobile/core/mock/entities/event.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/event_details_args.dart';
import 'package:your_space_mobile/core/router/args/event_form_args.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_bottom_nav.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_list_tile.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';

import '../cubit/events_list_cubit/events_list_cubit.dart';
import '../cubit/events_list_cubit/events_list_state.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: 'events.list.title'.tr()),
      body: SafeArea(
        child: BlocBuilder<EventsListCubit, EventsListState>(
          builder: (context, state) => switch (state) {
            EventsListSuccess(:final events) => _EventsListBody(events: events),
            EventsListError(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context.read<EventsListCubit>().load(),
              ),
            _ => const AppLoadingIndicator(),
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(AppRoutes.eventForm, extra: const EventFormArgs()),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

class _EventsListBody extends StatelessWidget {
  final List<Event> events;

  const _EventsListBody({required this.events});

  String _subtitle(Event event) {
    final date = DateFormatterHelper.formatDate(event.eventDate);
    final guestCount = 'events.list.guestCount'.tr(namedArgs: {'count': '${event.totalGuestCount}'});
    if (date.isEmpty) return guestCount;
    return '$date · $guestCount';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            hintText: 'events.list.searchHint'.tr(),
            prefixIcon: Icons.search_rounded,
            onChanged: (value) => context.read<EventsListCubit>().search(value),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: events.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.event_rounded,
                    title: 'events.list.emptyTitle'.tr(),
                    actionLabel: 'events.list.emptyAction'.tr(),
                    onAction: () =>
                        context.pushNamed(AppRoutes.eventForm, extra: const EventFormArgs()),
                  )
                : SingleChildScrollView(
                    child: AppCard(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Column(
                        children: [
                          for (var i = 0; i < events.length; i++)
                            AppListTile(
                              icon: Icons.event_rounded,
                              title: events[i].name,
                              subtitle: _subtitle(events[i]),
                              trailing:
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                              divider: i != events.length - 1,
                              onTap: () => context.pushNamed(
                                AppRoutes.eventDetails,
                                extra: EventDetailsArgs(eventId: events[i].id, eventName: events[i].name),
                              ),
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

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/helpers/date_formatter_helper.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/event_details_args.dart';
import 'package:your_space_mobile/core/router/args/event_form_args.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_list_tile.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';
import 'package:your_space_mobile/features/events/domain/entities/event.dart';

import '../cubit/events_list_cubit/events_list_cubit.dart';
import '../cubit/events_list_cubit/events_list_state.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('events.list.title'.tr(), style: AppTextStyles.headlineSmall),
              ),
            ),
            Expanded(
              child: BlocBuilder<EventsListCubit, EventsListState>(
                builder: (context, state) => switch (state) {
                  EventsListSuccess(:final events, :final hasNextPage, :final isLoadingMore) =>
                    _EventsListBody(events: events, hasNextPage: hasNextPage, isLoadingMore: isLoadingMore),
                  EventsListError(:final message) => ErrorStateWidget(
                      message: message,
                      onRetry: () => context.read<EventsListCubit>().load(),
                    ),
                  _ => const AppLoadingIndicator(),
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(AppRoutes.eventForm, extra: const EventFormArgs()),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _EventsListBody extends StatefulWidget {
  final List<Event> events;
  final bool hasNextPage;
  final bool isLoadingMore;

  const _EventsListBody({
    required this.events,
    required this.hasNextPage,
    required this.isLoadingMore,
  });

  @override
  State<_EventsListBody> createState() => _EventsListBodyState();
}

class _EventsListBodyState extends State<_EventsListBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!widget.hasNextPage || widget.isLoadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      context.read<EventsListCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

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
            child: widget.events.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.event_rounded,
                    title: 'events.list.emptyTitle'.tr(),
                    actionLabel: 'events.list.emptyAction'.tr(),
                    onAction: () =>
                        context.pushNamed(AppRoutes.eventForm, extra: const EventFormArgs()),
                  )
                : AppCard(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: widget.events.length + (widget.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= widget.events.length) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: const AppLoadingIndicator(),
                          );
                        }
                        final event = widget.events[index];
                        return AppListTile(
                          icon: Icons.event_rounded,
                          title: event.name,
                          subtitle: _subtitle(event),
                          trailing:
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                          divider: index != widget.events.length - 1,
                          onTap: () => context.pushNamed(
                            AppRoutes.eventDetails,
                            extra: EventDetailsArgs(eventId: event.id, eventName: event.name),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

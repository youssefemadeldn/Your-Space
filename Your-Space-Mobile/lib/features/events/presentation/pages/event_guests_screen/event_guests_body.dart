import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/mock/entities/event_guest.dart';
import 'package:your_space_mobile/core/mock/entities/event_guest_status.dart';
import 'package:your_space_mobile/core/mock/entities/group.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/add_guests_args.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/widgets/app_badge.dart';
import 'package:your_space_mobile/core/widgets/app_chip.dart';
import 'package:your_space_mobile/core/widgets/app_profile_row.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';

import '../../cubit/event_guests_list_cubit/event_guests_list_cubit.dart';
import 'event_guest_actions_sheet.dart';

class EventGuestsBody extends StatelessWidget {
  final int eventId;
  final String eventName;
  final List<EventGuest> guests;
  final List<Group> groups;
  final EventGuestStatus? selectedStatus;
  final int? selectedGroupId;

  const EventGuestsBody({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.guests,
    required this.groups,
    required this.selectedStatus,
    required this.selectedGroupId,
  });

  static const _statusOptions = [
    null,
    EventGuestStatus.notInvited,
    EventGuestStatus.invited,
    EventGuestStatus.skipped,
  ];

  String _statusLabel(EventGuestStatus? status) => switch (status) {
        null => 'events.guests.statusAll'.tr(),
        EventGuestStatus.notInvited => 'events.guests.statusNotInvited'.tr(),
        EventGuestStatus.invited => 'events.guests.statusInvited'.tr(),
        EventGuestStatus.skipped => 'events.guests.statusSkipped'.tr(),
      };

  AppBadgeTone _statusTone(EventGuestStatus status) => switch (status) {
        EventGuestStatus.notInvited => AppBadgeTone.neutral,
        EventGuestStatus.invited => AppBadgeTone.success,
        EventGuestStatus.skipped => AppBadgeTone.warning,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final status in _statusOptions)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: 8.w),
                    child: AppChip(
                      label: _statusLabel(status),
                      selected: selectedStatus == status,
                      onTap: () => context.read<EventGuestsListCubit>().filterByStatus(status),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 40.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 8.w),
                  child: AppChip(
                    label: 'people.list.allChip'.tr(),
                    selected: selectedGroupId == null,
                    onTap: () => context.read<EventGuestsListCubit>().filterByGroup(null),
                  ),
                ),
                for (final group in groups)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: 8.w),
                    child: AppChip(
                      label: group.name,
                      selected: selectedGroupId == group.id,
                      onTap: () => context.read<EventGuestsListCubit>().filterByGroup(group.id),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: guests.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.people_outline_rounded,
                    title: 'events.guests.emptyTitle'.tr(),
                    actionLabel: 'events.guests.emptyAction'.tr(),
                    onAction: () async {
                      await context.pushNamed(
                        AppRoutes.addGuests,
                        extra: AddGuestsArgs(eventId: eventId, eventName: eventName),
                      );
                      if (context.mounted) context.read<EventGuestsListCubit>().load(eventId);
                    },
                  )
                : ListView.builder(
                    itemCount: guests.length,
                    itemBuilder: (context, index) {
                      final guest = guests[index];
                      return AppProfileRow(
                        name: guest.personName,
                        groupName: guest.groupName,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppBadge(label: _statusLabel(guest.status), tone: _statusTone(guest.status)),
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                              onPressed: () => EventGuestActionsSheet.open(context, guest: guest),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

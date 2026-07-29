import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/helpers/date_formatter_helper.dart';
import 'package:your_space_mobile/core/mock/entities/event.dart';
import 'package:your_space_mobile/core/mock/entities/event_guest_progress_summary.dart';
import 'package:your_space_mobile/core/mock/entities/group_guest_progress.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/add_guests_args.dart';
import 'package:your_space_mobile/core/router/args/event_guests_args.dart';
import 'package:your_space_mobile/core/router/args/reciprocity_suggestions_args.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';

import '../../cubit/event_details_cubit/event_details_cubit.dart';
import 'event_guest_progress_bar.dart';

class EventDetailsBody extends StatelessWidget {
  final Event event;
  final EventGuestProgressSummary progress;

  const EventDetailsBody({super.key, required this.event, required this.progress});

  Future<void> _openGuests(BuildContext context) async {
    await context.pushNamed(
      AppRoutes.eventGuests,
      extra: EventGuestsArgs(eventId: event.id, eventName: event.name),
    );
    if (context.mounted) context.read<EventDetailsCubit>().loadDetails(event.id);
  }

  Future<void> _openAddGuests(BuildContext context) async {
    await context.pushNamed(
      AppRoutes.addGuests,
      extra: AddGuestsArgs(eventId: event.id, eventName: event.name),
    );
    if (context.mounted) context.read<EventDetailsCubit>().loadDetails(event.id);
  }

  Future<void> _openReciprocitySuggestions(BuildContext context) async {
    await context.pushNamed(
      AppRoutes.reciprocitySuggestions,
      extra: ReciprocitySuggestionsArgs(eventId: event.id, eventName: event.name),
    );
    if (context.mounted) context.read<EventDetailsCubit>().loadDetails(event.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.eventDate != null) ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 16.w, color: AppColors.textSecondary),
                      SizedBox(width: 6.w),
                      Text(
                        DateFormatterHelper.formatDate(event.eventDate),
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                ],
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('events.details.guestProgressTitle'.tr(), style: AppTextStyles.titleMedium),
                      SizedBox(height: 12.h),
                      Text(
                        '${progress.totalGuestCount}',
                        style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
                      ),
                      SizedBox(height: 12.h),
                      EventGuestProgressBar(
                        notInvitedCount: progress.notInvitedCount,
                        invitedCount: progress.invitedCount,
                        skippedCount: progress.skippedCount,
                      ),
                      SizedBox(height: 10.h),
                      if (progress.totalGuestCount == 0)
                        Text(
                          'events.details.noGuestsHint'.tr(),
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        )
                      else
                        Wrap(
                          spacing: 12.w,
                          runSpacing: 4.h,
                          children: [
                            _Legend(
                              color: AppColors.success,
                              label: 'events.guests.statusInvited'.tr(),
                              count: progress.invitedCount,
                            ),
                            _Legend(
                              color: AppColors.textHint,
                              label: 'events.guests.statusSkipped'.tr(),
                              count: progress.skippedCount,
                            ),
                            _Legend(
                              color: AppColors.divider,
                              label: 'events.guests.statusNotInvited'.tr(),
                              count: progress.notInvitedCount,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Text('events.details.byGroupTitle'.tr(), style: AppTextStyles.titleMedium),
                SizedBox(height: 8.h),
                AppCard(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    children: [
                      for (var i = 0; i < progress.groups.length; i++)
                        _GroupProgressRow(
                          progress: progress.groups[i],
                          showDivider: i != progress.groups.length - 1,
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _openReciprocitySuggestions(context),
                    icon: const Icon(Icons.favorite_border_rounded),
                    label: Text('events.details.reciprocitySuggestionsCta'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'events.details.manageGuestsCta'.tr(),
                    variant: AppButtonVariant.secondary,
                    onPressed: progress.totalGuestCount == 0 ? null : () => _openGuests(context),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: AppButton(
                    label: 'events.details.addGuestsCta'.tr(),
                    icon: Icons.person_add_rounded,
                    onPressed: () => _openAddGuests(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _Legend({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8.w, height: 8.w, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 6.w),
        Text('$count $label', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _GroupProgressRow extends StatelessWidget {
  final GroupGuestProgress progress;
  final bool showDivider;

  const _GroupProgressRow({required this.progress, required this.showDivider});

  String get _caption {
    if (progress.guestsAddedCount == 0) {
      return 'events.details.groupNoneAdded'.tr(namedArgs: {'total': '${progress.totalPersonsInGroup}'});
    }
    return 'events.details.groupCaption'.tr(namedArgs: {
      'total': '${progress.totalPersonsInGroup}',
      'added': '${progress.guestsAddedCount}',
      'notInvited': '${progress.notInvitedCount}',
      'invited': '${progress.invitedCount}',
      'skipped': '${progress.skippedCount}',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(progress.groupName, style: AppTextStyles.titleMedium),
          SizedBox(height: 2.h),
          Text(_caption, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          if (showDivider) ...[
            SizedBox(height: 10.h),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

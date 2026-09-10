import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/helpers/date_formatter_helper.dart';
import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/features/people/domain/entities/person_occasion_history_entry.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_avatar.dart';
import 'package:your_space_mobile/core/widgets/app_badge.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';

import 'add_occasion_sheet.dart';

class PersonDetailsBody extends StatelessWidget {
  final Person person;
  final List<PersonOccasionHistoryEntry> occasions;

  const PersonDetailsBody({super.key, required this.person, required this.occasions});

  void _openAddOccasion(BuildContext context) {
    AddOccasionSheet.open(context, personId: person.id, personName: person.name);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                AppAvatar(name: person.name, size: 72.w, photoUrl: person.primaryPhotoUrl),
                SizedBox(height: 10.h),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(person.name, style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBadge(label: person.groupName, tone: AppBadgeTone.neutral),
                    if (person.phoneNumber != null) ...[
                      SizedBox(width: 8.w),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(person.phoneNumber!, style: AppTextStyles.bodySmall),
                      ),
                    ],
                    if (person.phoneNumber2 != null) ...[
                      SizedBox(width: 8.w),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(person.phoneNumber2!, style: AppTextStyles.bodySmall),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (person.hasReciprocityHistory) ...[
            SizedBox(height: 16.h),
            AppCard(
              elevated: false,
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: AppColors.primary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'people.details.reciprocityBanner'.tr(namedArgs: {'name': person.name}),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (person.notes != null && person.notes!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text('people.details.notesTitle'.tr(), style: AppTextStyles.titleMedium),
            SizedBox(height: 6.h),
            Text(person.notes!, style: AppTextStyles.bodySmall),
          ],
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('people.details.occasionsTitle'.tr(), style: AppTextStyles.titleMedium),
              TextButton(
                onPressed: () => _openAddOccasion(context),
                child: Text('people.details.addOccasion'.tr()),
              ),
            ],
          ),
          if (occasions.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: EmptyStateWidget(
                icon: Icons.history_rounded,
                title: 'people.details.emptyTitle'.tr(namedArgs: {'name': person.name}),
                actionLabel: 'people.details.emptyAction'.tr(),
                onAction: () => _openAddOccasion(context),
              ),
            )
          else
            AppCard(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Column(
                children: [
                  for (var i = 0; i < occasions.length; i++)
                    _OccasionTile(entry: occasions[i], showDivider: i != occasions.length - 1),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OccasionTile extends StatelessWidget {
  final PersonOccasionHistoryEntry entry;
  final bool showDivider;

  const _OccasionTile({required this.entry, required this.showDivider});

  IconData get _icon {
    if (!entry.invitedMe) return Icons.do_not_disturb_on_outlined;
    return switch (entry.inviteMethod) {
      InviteMethod.whatsApp => Icons.chat_rounded,
      InviteMethod.phoneCall => Icons.call_rounded,
      InviteMethod.physical => Icons.handshake_rounded,
      null => Icons.event_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: 10.h, horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, size: 20.w, color: AppColors.textSecondary),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  entry.occasionName ?? 'people.details.occasionUnnamed'.tr(),
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (entry.occasionDate != null)
                Text(DateFormatterHelper.formatDate(entry.occasionDate), style: AppTextStyles.bodySmall),
            ],
          ),
          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(entry.notes!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
          if (showDivider) ...[
            SizedBox(height: 10.h),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

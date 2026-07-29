import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/helpers/bottom_sheet_helper.dart';
import 'package:your_space_mobile/core/mock/entities/event_guest.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';

import '../../cubit/event_guest_action_cubit/event_guest_action_cubit.dart';
import 'event_guest_invite_method_sheet.dart';

/// 4 always-available actions — no state-machine guard, matching the backend
/// brief's documented behavior for `EventGuest` status transitions.
class EventGuestActionsSheet extends StatelessWidget {
  final EventGuest guest;

  const EventGuestActionsSheet({super.key, required this.guest});

  static Future<void> open(BuildContext context, {required EventGuest guest}) {
    final actionCubit = context.read<EventGuestActionCubit>();
    return BottomSheetHelper.showAppBottomSheet(
      context,
      BlocProvider.value(value: actionCubit, child: EventGuestActionsSheet(guest: guest)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionCubit = context.read<EventGuestActionCubit>();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(guest.personName, style: AppTextStyles.titleMedium),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat_rounded),
            title: Text('events.guests.actionMarkInvited'.tr()),
            onTap: () async {
              Navigator.of(context).pop();
              final method =
                  await EventGuestInviteMethodSheet.open(context, personName: guest.personName);
              if (method != null) actionCubit.markInvited(guest.id, inviteMethod: method);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_rounded),
            title: Text('events.guests.actionSkip'.tr()),
            onTap: () {
              Navigator.of(context).pop();
              actionCubit.markSkipped(guest.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.undo_rounded),
            title: Text('events.guests.actionRevert'.tr()),
            onTap: () {
              Navigator.of(context).pop();
              actionCubit.revert(guest.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            title: Text('events.guests.actionRemove'.tr(), style: const TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.of(context).pop();
              actionCubit.remove(guest.id);
            },
          ),
        ],
      ),
    );
  }
}

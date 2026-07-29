import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/helpers/bottom_sheet_helper.dart';
import 'package:your_space_mobile/core/mock/entities/invite_method.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/invite_method_chip_group.dart';

/// Reused as-is from the Occasion History sheet's method-chip picker — shown
/// before confirming "Mark invited" on an event guest.
class EventGuestInviteMethodSheet extends StatefulWidget {
  final String personName;

  const EventGuestInviteMethodSheet({super.key, required this.personName});

  static Future<InviteMethod?> open(BuildContext context, {required String personName}) {
    return BottomSheetHelper.showAppBottomSheet<InviteMethod>(
      context,
      EventGuestInviteMethodSheet(personName: personName),
    );
  }

  @override
  State<EventGuestInviteMethodSheet> createState() => _EventGuestInviteMethodSheetState();
}

class _EventGuestInviteMethodSheetState extends State<EventGuestInviteMethodSheet> {
  InviteMethod? _selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'events.guests.inviteMethodTitle'.tr(namedArgs: {'name': widget.personName}),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          InviteMethodChipGroup(
            selected: _selected,
            onChanged: (method) => setState(() => _selected = method),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'common.cancel'.tr(),
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AppButton(
                  label: 'events.guests.inviteMethodConfirm'.tr(),
                  onPressed: _selected == null ? null : () => Navigator.of(context).pop(_selected),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

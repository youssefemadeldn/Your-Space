import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/theme/app_colors.dart';

class EventGuestProgressBar extends StatelessWidget {
  final int notInvitedCount;
  final int invitedCount;
  final int skippedCount;

  const EventGuestProgressBar({
    super.key,
    required this.notInvitedCount,
    required this.invitedCount,
    required this.skippedCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = notInvitedCount + invitedCount + skippedCount;
    if (total == 0) {
      return Container(
        height: 10.h,
        decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(6.r)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: SizedBox(
        height: 10.h,
        child: Row(
          children: [
            if (invitedCount > 0) Expanded(flex: invitedCount, child: Container(color: AppColors.success)),
            if (skippedCount > 0) Expanded(flex: skippedCount, child: Container(color: AppColors.textHint)),
            if (notInvitedCount > 0)
              Expanded(flex: notInvitedCount, child: Container(color: AppColors.divider)),
          ],
        ),
      ),
    );
  }
}

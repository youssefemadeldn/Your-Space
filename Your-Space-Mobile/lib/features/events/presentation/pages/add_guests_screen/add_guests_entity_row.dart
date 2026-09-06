import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';

/// One "name + total person count + add" row — the shape shared by the
/// group/subgroup/governorate/city/neighborhood bulk-add tabs. [onAdd] is
/// null (button disabled) when there's nobody to add.
class AddGuestsEntityRow extends StatelessWidget {
  final String name;
  final int personCount;
  final bool submitting;
  final VoidCallback? onAdd;

  const AddGuestsEntityRow({
    super.key,
    required this.name,
    required this.personCount,
    required this.submitting,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    'events.addGuests.groupPeopleCount'.tr(namedArgs: {'count': '$personCount'}),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            AppButton(
              label: 'events.addGuests.addGroupCta'.tr(),
              variant: AppButtonVariant.soft,
              size: AppButtonSize.sm,
              loading: submitting,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

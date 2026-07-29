import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../mock/entities/invite_method.dart';
import 'app_chip.dart';

/// The exact chip-picker reused, unbuilt, between People's Add-Occasion sheet
/// and Events' invite-method-confirm sheet — lives in `core/` since it crosses
/// a feature boundary.
class InviteMethodChipGroup extends StatelessWidget {
  final InviteMethod? selected;
  final ValueChanged<InviteMethod> onChanged;

  const InviteMethodChipGroup({super.key, this.selected, required this.onChanged});

  static const _icons = {
    InviteMethod.whatsApp: Icons.chat_rounded,
    InviteMethod.phoneCall: Icons.call_rounded,
    InviteMethod.physical: Icons.handshake_rounded,
  };

  static const _labelKeys = {
    InviteMethod.whatsApp: 'common.inviteMethod.whatsApp',
    InviteMethod.phoneCall: 'common.inviteMethod.phoneCall',
    InviteMethod.physical: 'common.inviteMethod.physical',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: InviteMethod.values.map((method) {
        return AppChip(
          label: _labelKeys[method]!.tr(),
          icon: _icons[method],
          selected: method == selected,
          onTap: () => onChanged(method),
        );
      }).toList(),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../entities/gender.dart';
import 'app_chip.dart';

/// A binary chip picker for Gender — reused, unbuilt, between Register and
/// the Person form — lives in `core/` since it crosses a feature boundary.
/// Mirrors `InviteMethodChipGroup`'s exact shape.
class GenderChipGroup extends StatelessWidget {
  final Gender? selected;
  final ValueChanged<Gender> onChanged;

  const GenderChipGroup({super.key, this.selected, required this.onChanged});

  static const _icons = {
    Gender.male: Icons.male_rounded,
    Gender.female: Icons.female_rounded,
  };

  static const _labelKeys = {
    Gender.male: 'common.gender.male',
    Gender.female: 'common.gender.female',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: Gender.values.map((gender) {
        return AppChip(
          label: _labelKeys[gender]!.tr(),
          icon: _icons[gender],
          selected: gender == selected,
          onTap: () => onChanged(gender),
        );
      }).toList(),
    );
  }
}

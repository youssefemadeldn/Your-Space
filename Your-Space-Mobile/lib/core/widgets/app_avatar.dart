import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Initials-on-tint only — no photo support. Matches the design system's
/// explicit "no real photos, initials-on-tint" decision (no backend DTO
/// exposes an avatar URL for Group/Person/Event either).
class AppAvatar extends StatelessWidget {
  final String name;
  final double? size;

  const AppAvatar({super.key, required this.name, this.size});

  static const _backgrounds = [
    AppColors.brandRedSoft,
    AppColors.tintInfo,
    AppColors.tintSuccess,
    AppColors.tintWarning,
    AppColors.inputFill,
  ];

  static const _foregrounds = [
    AppColors.primary,
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    AppColors.textSecondary,
  ];

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first.substring(0, 1);
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1].substring(0, 1) : '';
    return (first + second).toUpperCase();
  }

  int get _toneIndex => trimmedIsEmpty ? 0 : name.trim().codeUnits.first % _backgrounds.length;

  bool get trimmedIsEmpty => name.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size ?? 44.w;
    final index = _toneIndex;

    return CircleAvatar(
      radius: resolvedSize / 2,
      backgroundColor: _backgrounds[index],
      child: Text(
        _initials,
        style: AppTextStyles.labelLarge.copyWith(color: _foregrounds[index]),
      ),
    );
  }
}

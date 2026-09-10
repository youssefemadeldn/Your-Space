import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Initials-on-tint by default; renders [photoUrl] via [CachedNetworkImage] when provided,
/// falling back to initials on null/empty/load-error (including a presigned URL past its
/// expiry — a graceful fallback, not a broken-image icon). Reverses this widget's earlier
/// "no real photos" decision now that Person/AppUser can carry a real profile photo — see
/// Sprint 3 (Photos + Cloudflare R2).
class AppAvatar extends StatelessWidget {
  final String name;
  final double? size;
  final String? photoUrl;

  const AppAvatar({super.key, required this.name, this.size, this.photoUrl});

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

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: resolvedSize,
          height: resolvedSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => _initialsCircle(resolvedSize),
          errorWidget: (context, url, error) => _initialsCircle(resolvedSize),
        ),
      );
    }

    return _initialsCircle(resolvedSize);
  }

  Widget _initialsCircle(double resolvedSize) {
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

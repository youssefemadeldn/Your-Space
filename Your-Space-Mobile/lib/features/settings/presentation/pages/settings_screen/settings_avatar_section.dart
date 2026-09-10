import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/bottom_sheet_helper.dart';
import 'package:your_space_mobile/core/helpers/dialog_helper.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_shadows.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_avatar.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';

import 'package:your_space_mobile/features/auth/domain/entities/user_profile.dart';

/// Screen-scoped — not shared across 2+ screens, so it lives next to SettingsScreen
/// rather than in core/widgets (Mobile CLAUDE.md §1.1).
class SettingsAvatarSection extends StatelessWidget {
  final UserProfile profile;
  final bool isUpdating;
  final ValueChanged<File> onPickImage;
  final VoidCallback onRemove;

  const SettingsAvatarSection({
    super.key,
    required this.profile,
    required this.isUpdating,
    required this.onPickImage,
    required this.onRemove,
  });

  Future<void> _openPicker(BuildContext context) async {
    final source = await BottomSheetHelper.showAppBottomSheet<ImageSource>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text('settings.takePhoto'.tr(), style: AppTextStyles.bodyMedium),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text('settings.chooseFromGallery'.tr(), style: AppTextStyles.bodyMedium),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    onPickImage(File(picked.path));
  }

  void _confirmRemove() {
    getIt<DialogHelper>().showConfirmDialog(
      title: 'settings.removePhotoConfirmTitle'.tr(),
      message: 'settings.removePhotoConfirmMessage'.tr(),
      confirmText: 'settings.removePhoto'.tr(),
      cancelText: 'common.cancel'.tr(),
      onConfirm: onRemove,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: 72.w,
              height: 72.w,
              child: isUpdating
                  ? DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.inputFill, shape: BoxShape.circle),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
                    )
                  : AppAvatar(
                      name: '${profile.firstName} ${profile.lastName}',
                      size: 72.w,
                      photoUrl: profile.avatarUrl,
                    ),
            ),
            PositionedDirectional(
              end: -4.w,
              bottom: -4.h,
              child: Material(
                color: AppColors.surface,
                shape: const CircleBorder(),
                elevation: 0,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isUpdating ? null : () => _openPicker(context),
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: AppShadows.soft,
                    ),
                    child: Icon(Icons.photo_camera_rounded, size: 16.w, color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: 'settings.replacePhoto'.tr(),
              variant: AppButtonVariant.text,
              size: AppButtonSize.sm,
              icon: Icons.edit_outlined,
              onPressed: isUpdating ? null : () => _openPicker(context),
            ),
            if (hasPhoto) ...[
              SizedBox(width: 8.w),
              TextButton.icon(
                onPressed: isUpdating ? null : _confirmRemove,
                icon: Icon(Icons.delete_outline_rounded, size: 18.w, color: AppColors.error),
                label: Text(
                  'settings.removePhoto'.tr(),
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
        Text(
          'settings.photoHint'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

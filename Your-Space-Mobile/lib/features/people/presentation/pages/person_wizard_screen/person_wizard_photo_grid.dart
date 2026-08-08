import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import 'package:your_space_mobile/core/helpers/bottom_sheet_helper.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/staged_person_photo.dart';

const _maxPhotos = 6;

/// Step 1's 3-column photo grid — tap-anywhere-on-a-tile to mark it primary,
/// a dashed "add" tile while under the cap. Purely staged: [onAdd]/[onRemove]/
/// [onMarkPrimary] only touch local wizard state, no network calls (see
/// PersonWizardCubit's locked staged-photo model) — wizard-only, screen-local
/// widget, not shared across 2+ screens.
class PersonWizardPhotoGrid extends StatelessWidget {
  final List<StagedPersonPhoto> photos;
  final ValueChanged<File> onAdd;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onMarkPrimary;

  const PersonWizardPhotoGrid({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    required this.onMarkPrimary,
  });

  Future<void> _pickAndAdd(BuildContext context) async {
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

    onAdd(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final canAddMore = photos.length < _maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('people.wizard.step1.photosLabel'.tr(), style: AppTextStyles.titleMedium),
            Text(
              '${photos.length} / $_maxPhotos',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photos.length + (canAddMore ? 1 : 0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10.w,
            crossAxisSpacing: 10.w,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            if (index >= photos.length) {
              return _AddTile(onTap: () => _pickAndAdd(context));
            }
            final photo = photos[index];
            return _PhotoTile(
              photo: photo,
              onTap: () => onMarkPrimary(photo.localId),
              onRemove: () => onRemove(photo.localId),
            );
          },
        ),
        SizedBox(height: 8.h),
        Text(
          'people.wizard.step1.photosHint'.tr(),
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final StagedPersonPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PhotoTile({required this.photo, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: photo.localFile != null
                  ? Image.file(photo.localFile!, fit: BoxFit.cover)
                  : CachedNetworkImage(
                      imageUrl: photo.existingUrl ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const ColoredBox(color: AppColors.inputFill),
                    ),
            ),
          ),
          if (photo.isPrimary)
            PositionedDirectional(
              start: 6.w,
              top: 6.h,
              child: Container(
                padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999.r)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 12.w, color: AppColors.surface),
                    SizedBox(width: 2.w),
                    Text(
                      'people.wizard.step1.primaryBadge'.tr(),
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.surface, fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
            ),
          PositionedDirectional(
            end: 4.w,
            top: 4.h,
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Container(
                width: 22.w,
                height: 22.w,
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: Icon(Icons.close_rounded, size: 14.w, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: DottedBorderBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 22.w, color: AppColors.primary),
            SizedBox(height: 4.h),
            Text(
              'people.wizard.step1.addPhoto'.tr(),
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small local helper — a dashed-border container. Flutter has no built-in
/// dashed border, and this is the only place in the app that needs one, so
/// it's a minimal `CustomPaint` rather than a new package dependency.
class DottedBorderBox extends StatelessWidget {
  final Widget child;

  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: AppColors.primary, radius: 16.r),
      child: Container(
        decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(16.r)),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(metric.extractPath(distance, distance + 5), Offset.zero);
        distance += 9;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

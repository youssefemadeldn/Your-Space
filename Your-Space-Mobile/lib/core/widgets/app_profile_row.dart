import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_text_styles.dart';
import 'app_avatar.dart';
import 'app_badge.dart';

/// The recurring "Avatar + name + group pill + trailing" row used across
/// People, Event Guests, Add-Guests, and Reciprocity Suggestions. Name and
/// phone are isolated to LTR (matching [AppOtpInput]'s precedent) since raw
/// identity data must not mirror under Arabic — the group badge is left
/// direction-neutral since it's ordinary translated content.
class AppProfileRow extends StatelessWidget {
  final String name;
  final String? groupName;
  final String? phoneNumber;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppProfileRow({
    super.key,
    required this.name,
    this.groupName,
    this.phoneNumber,
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: 8.h),
      child: Row(
        children: [
          leading ?? AppAvatar(name: name),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    name,
                    style: AppTextStyles.titleMedium,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (groupName != null || phoneNumber != null) ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      if (groupName != null) ...[
                        AppBadge(label: groupName!, tone: AppBadgeTone.neutral),
                        if (phoneNumber != null) SizedBox(width: 6.w),
                      ],
                      if (phoneNumber != null)
                        Flexible(
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              phoneNumber!,
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 8.w),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

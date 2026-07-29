import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final bool elevated;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.elevated = true,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28.r);
    final padded = Padding(padding: padding ?? EdgeInsets.all(16.w), child: child);

    // Material itself carries the card's background — children (e.g.
    // ListTile/InkWell rows) paint ink splashes on the nearest Material
    // ancestor, and an opaque Container/DecoratedBox sitting between it and
    // them would silently paint over that ink, which a plain Container here
    // used to do.
    Widget card = Material(
      color: AppColors.cardBackground,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? padded : InkWell(onTap: onTap, child: padded),
    );

    if (elevated) {
      card = Container(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: AppShadows.soft),
        child: card,
      );
    }

    return card;
  }
}

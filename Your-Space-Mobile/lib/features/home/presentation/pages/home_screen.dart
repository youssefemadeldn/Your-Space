import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_avatar.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';
import 'package:your_space_mobile/core/widgets/app_list_tile.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';

import '../cubit/home_stats_cubit/home_stats_cubit.dart';
import '../cubit/home_stats_cubit/home_stats_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeStatsCubit, HomeStatsState>(
          builder: (context, state) => switch (state) {
            HomeStatsSuccess(:final groupsCount, :final peopleCount, :final eventsCount, :final firstName) =>
              _HomeContent(
                groupsCount: groupsCount,
                peopleCount: peopleCount,
                eventsCount: eventsCount,
                firstName: firstName,
              ),
            HomeStatsError(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context.read<HomeStatsCubit>().load(),
              ),
            _ => const AppLoadingIndicator(),
          },
        ),
      ),
    );
  }
}

/// Time-of-day greeting key, matching the design mockup's "Good evening"
/// header line — resolved dynamically instead of hardcoded so it's actually
/// correct outside the evening.
String _greetingKey() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'home.greetingMorning';
  if (hour < 17) return 'home.greetingAfternoon';
  return 'home.greetingEvening';
}

class _HomeContent extends StatelessWidget {
  final int groupsCount;
  final int peopleCount;
  final int eventsCount;
  final String firstName;

  const _HomeContent({
    required this.groupsCount,
    required this.peopleCount,
    required this.eventsCount,
    required this.firstName,
  });

  Widget get _header => Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Row(
          children: [
            AppAvatar(name: firstName, size: 44.w),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greetingKey().tr(),
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    'home.hiName'.tr(namedArgs: {'name': firstName}),
                    style: AppTextStyles.headlineSmall,
                  ),
                ],
              ),
            ),
            // Static for now — no notifications feature exists yet (no backend,
            // no badge data); matches the design mockup's header slot as a
            // non-functional placeholder rather than inventing a fake feature.
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (groupsCount == 0) {
      return Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header,
            Expanded(
              child: EmptyStateWidget(
                icon: Icons.groups_rounded,
                title: 'home.emptyTitle'.tr(),
                subtitle: 'home.emptySubtitle'.tr(),
                actionLabel: 'home.emptyAction'.tr(),
                onAction: () => context.go(AppRoutes.groups),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header,
          Row(
            children: [
              Expanded(
                child: AppCard(
                  onTap: () => context.go(AppRoutes.groups),
                  child: _StatColumn(label: 'home.groupsLabel'.tr(), count: groupsCount),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AppCard(
                  onTap: () => context.go(AppRoutes.people),
                  child: _StatColumn(label: 'home.peopleLabel'.tr(), count: peopleCount),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          AppCard(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Column(
              children: [
                AppListTile(
                  icon: Icons.groups_rounded,
                  title: 'home.groupsLabel'.tr(),
                  subtitle: '$groupsCount',
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  divider: true,
                  onTap: () => context.go(AppRoutes.groups),
                ),
                AppListTile(
                  icon: Icons.people_alt_rounded,
                  title: 'home.peopleLabel'.tr(),
                  subtitle: '$peopleCount',
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  divider: true,
                  onTap: () => context.go(AppRoutes.people),
                ),
                AppListTile(
                  icon: Icons.event_rounded,
                  title: 'home.eventsLabel'.tr(),
                  subtitle: '$eventsCount',
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  onTap: () => context.go(AppRoutes.events),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int count;

  const _StatColumn({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
        ),
        SizedBox(height: 4.h),
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

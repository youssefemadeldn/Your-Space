import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/dialog_helper.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/storage/secure_storage_helper.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_bottom_nav.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';
import 'package:your_space_mobile/core/widgets/app_list_tile.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/app_logo_header.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';

import '../cubit/home_stats_cubit/home_stats_cubit.dart';
import '../cubit/home_stats_cubit/home_stats_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'home.title'.tr(),
        trailing: IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'common.logout'.tr(),
          onPressed: () => _confirmLogout(context),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<HomeStatsCubit, HomeStatsState>(
          builder: (context, state) => switch (state) {
            HomeStatsSuccess(:final groupsCount, :final peopleCount, :final eventsCount) =>
              _HomeContent(groupsCount: groupsCount, peopleCount: peopleCount, eventsCount: eventsCount),
            HomeStatsError(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context.read<HomeStatsCubit>().load(),
              ),
            _ => const AppLoadingIndicator(),
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

void _confirmLogout(BuildContext context) {
  getIt<DialogHelper>().showConfirmDialog(
    title: 'common.logoutConfirmTitle'.tr(),
    message: 'common.logoutConfirmMessage'.tr(),
    confirmText: 'common.logout'.tr(),
    cancelText: 'common.cancel'.tr(),
    onConfirm: () async {
      await getIt<SecureStorageHelper>().clearSession();
      if (!context.mounted) return;
      context.go(AppRoutes.login);
    },
  );
}

class _HomeContent extends StatelessWidget {
  final int groupsCount;
  final int peopleCount;
  final int eventsCount;

  const _HomeContent({
    required this.groupsCount,
    required this.peopleCount,
    required this.eventsCount,
  });

  Widget get _logoLockup => AppLogoHeader(
        compact: true,
        centered: false,
        logoSize: 28.w,
        padding: EdgeInsets.only(bottom: 16.h),
      );

  @override
  Widget build(BuildContext context) {
    if (groupsCount == 0) {
      return Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _logoLockup,
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
          _logoLockup,
          Text('home.greeting'.tr(), style: AppTextStyles.headlineSmall),
          SizedBox(height: 16.h),
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

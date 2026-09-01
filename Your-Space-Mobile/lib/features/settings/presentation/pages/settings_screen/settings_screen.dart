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
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';
import 'package:your_space_mobile/core/widgets/app_list_tile.dart';

import 'package:your_space_mobile/features/auth/presentation/cubit/delete_account_cubit/delete_account_cubit.dart';
import 'delete_account_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'settings.title'.tr(),
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: AppCard(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Column(
              children: [
                AppListTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'settings.changePassword'.tr(),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  divider: true,
                  onTap: () => context.pushNamed(AppRoutes.changePassword),
                ),
                AppListTile(
                  icon: Icons.logout_rounded,
                  title: 'settings.logout'.tr(),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  divider: true,
                  onTap: () => _confirmLogout(context),
                ),
                AppListTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'settings.deleteAccount'.tr(),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  onTap: () => _confirmDeleteAccount(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  void _confirmDeleteAccount(BuildContext context) {
    final cubit = context.read<DeleteAccountCubit>();
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: DeleteAccountDialog(host: context),
      ),
    );
  }
}

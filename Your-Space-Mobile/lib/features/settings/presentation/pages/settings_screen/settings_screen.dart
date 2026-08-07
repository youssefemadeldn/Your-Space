import 'dart:io';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/dialog_helper.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/storage/secure_storage_helper.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_list_tile.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';

import 'package:your_space_mobile/features/auth/domain/entities/user_profile.dart';

import '../../cubit/profile_form_cubit/profile_form_cubit.dart';
import '../../cubit/profile_form_cubit/profile_form_state.dart';
import 'settings_avatar_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _fieldsInitialized = false;

  // Refreshed from every state variant that carries one — unlike the text
  // controllers above (which must only ever seed once so they don't fight
  // in-progress typing), the avatar must always reflect the latest known
  // profile after every mutation.
  UserProfile? _profile;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _seedFromState(ProfileFormState state) {
    final profile = switch (state) {
      ProfileFormReady(:final profile) => profile,
      ProfileFormSuccess(:final profile) => profile,
      ProfileFormAvatarUploading(:final profile) => profile,
      ProfileFormAvatarSuccess(:final profile) => profile,
      ProfileFormAvatarError(:final profile) => profile,
      _ => null,
    };
    if (profile == null) return;

    _profile = profile;
    if (!_fieldsInitialized) {
      _fieldsInitialized = true;
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _phoneController.text = profile.phoneNumber ?? '';
    }
  }

  void _save() {
    context.read<ProfileFormCubit>().submit(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );
  }

  void _confirmLogout() {
    getIt<DialogHelper>().showConfirmDialog(
      title: 'common.logoutConfirmTitle'.tr(),
      message: 'common.logoutConfirmMessage'.tr(),
      confirmText: 'common.logout'.tr(),
      cancelText: 'common.cancel'.tr(),
      onConfirm: () async {
        await getIt<SecureStorageHelper>().clearSession();
        if (!mounted) return;
        context.go(AppRoutes.login);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('settings.title'.tr(), style: AppTextStyles.headlineSmall),
              SizedBox(height: 16.h),
              Expanded(
                child: BlocConsumer<ProfileFormCubit, ProfileFormState>(
                  listener: (context, state) {
                    if (state is ProfileFormSuccess) {
                      getIt<SnackBarHelper>().showSuccess('settings.savedMessage'.tr());
                    } else if (state is ProfileFormError) {
                      getIt<SnackBarHelper>().showError(state.message);
                    } else if (state is ProfileFormAvatarSuccess) {
                      final message = state.profile.avatarUrl != null
                          ? 'settings.photoUpdated'.tr()
                          : 'settings.photoRemoved'.tr();
                      getIt<SnackBarHelper>().showSuccess(message);
                    } else if (state is ProfileFormAvatarError) {
                      getIt<SnackBarHelper>().showError(state.message);
                    }
                  },
                  builder: (context, state) {
                    if (state is ProfileFormInitial || state is ProfileFormLoading) {
                      return const AppLoadingIndicator();
                    }
                    if (state is ProfileFormError && !_fieldsInitialized) {
                      return ErrorStateWidget(
                        message: state.message,
                        onRetry: () => context.read<ProfileFormCubit>().initialize(),
                      );
                    }
                    _seedFromState(state);
                    final profile = _profile;
                    if (profile == null) {
                      return const AppLoadingIndicator();
                    }

                    final submitting = state is ProfileFormSubmitting;
                    final avatarUpdating = state is ProfileFormAvatarUploading;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: SettingsAvatarSection(
                              profile: profile,
                              isUpdating: avatarUpdating,
                              onPickImage: (File file) =>
                                  context.read<ProfileFormCubit>().uploadAvatar(file),
                              onRemove: () => context.read<ProfileFormCubit>().removeAvatar(),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          AppCard(
                            child: Column(
                              children: [
                                AppInput(
                                  label: 'auth.firstName'.tr(),
                                  controller: _firstNameController,
                                  enabled: !submitting,
                                ),
                                SizedBox(height: 14.h),
                                AppInput(
                                  label: 'auth.lastName'.tr(),
                                  controller: _lastNameController,
                                  enabled: !submitting,
                                ),
                                SizedBox(height: 14.h),
                                AppInput(
                                  label: 'auth.phone'.tr(),
                                  keyboardType: TextInputType.phone,
                                  textDirection: TextDirection.ltr,
                                  controller: _phoneController,
                                  enabled: !submitting,
                                ),
                                SizedBox(height: 14.h),
                                AppButton(
                                  label: 'common.saveChanges'.tr(),
                                  fullWidth: true,
                                  loading: submitting,
                                  onPressed: submitting ? null : _save,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          AppCard(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: AppListTile(
                              icon: Icons.logout_rounded,
                              iconColor: AppColors.error,
                              title: 'common.logout'.tr(),
                              titleColor: AppColors.error,
                              onTap: _confirmLogout,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/regex_helper.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_password_input.dart';

import '../cubit/change_password_cubit/change_password_cubit.dart';
import '../cubit/change_password_cubit/change_password_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmNewPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmNewPassword = _confirmNewPasswordController.text;
    setState(() {
      _currentPasswordError =
          currentPassword.isEmpty ? 'auth.validation.requiredCurrentPassword'.tr() : null;
      _newPasswordError = switch (newPassword) {
        _ when !RegexHelper.validate(RegexHelper.accountPassword, newPassword) => 'auth.passwordRule'.tr(),
        _ when newPassword == currentPassword => 'auth.validation.newPasswordSameAsCurrent'.tr(),
        _ => null,
      };
      _confirmNewPasswordError =
          confirmNewPassword == newPassword ? null : 'auth.validation.passwordMismatch'.tr();
    });
    return _currentPasswordError == null &&
        _newPasswordError == null &&
        _confirmNewPasswordError == null;
  }

  void _submit() {
    if (!_validate()) return;
    context.read<ChangePasswordCubit>().submit(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmNewPassword: _confirmNewPasswordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'auth.changePassword.title'.tr(),
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: BlocListener<ChangePasswordCubit, ChangePasswordState>(
          listener: (context, state) {
            if (state is ChangePasswordSuccess) {
              context.go(AppRoutes.login);
              getIt<SnackBarHelper>().showSuccess('auth.changePassword.doneMessage'.tr());
              return;
            }
            if (state is ChangePasswordError) {
              if (state.isNetworkError) {
                getIt<SnackBarHelper>().showError(
                  'common.networkError'.tr(),
                  actionLabel: 'common.retry'.tr(),
                  onAction: _submit,
                );
                return;
              }
              // The backend collapses every failure on this endpoint (wrong
              // current password or a rejected new password) into one
              // Validation.Failed code — shown inline under Current Password,
              // the only realistic real-world failure for this screen.
              setState(() => _currentPasswordError = state.message);
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPasswordInput(
                  label: 'auth.currentPassword'.tr(),
                  controller: _currentPasswordController,
                  errorText: _currentPasswordError,
                  onChanged: (_) {
                    if (_currentPasswordError != null) setState(() => _currentPasswordError = null);
                  },
                ),
                SizedBox(height: 14.h),
                AppPasswordInput(
                  label: 'auth.newPassword'.tr(),
                  controller: _newPasswordController,
                  errorText: _newPasswordError,
                  helperText: 'auth.passwordRule'.tr(),
                  onChanged: (_) {
                    if (_newPasswordError != null) setState(() => _newPasswordError = null);
                  },
                ),
                SizedBox(height: 14.h),
                AppPasswordInput(
                  label: 'auth.confirmNewPassword'.tr(),
                  controller: _confirmNewPasswordController,
                  errorText: _confirmNewPasswordError,
                  onChanged: (_) {
                    if (_confirmNewPasswordError != null) setState(() => _confirmNewPasswordError = null);
                  },
                ),
                SizedBox(height: 20.h),
                BlocBuilder<ChangePasswordCubit, ChangePasswordState>(
                  builder: (context, state) => AppButton(
                    label: 'auth.changePassword.submit'.tr(),
                    fullWidth: true,
                    loading: state is ChangePasswordLoading,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

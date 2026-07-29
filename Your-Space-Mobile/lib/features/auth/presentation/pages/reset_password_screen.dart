import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/regex_helper.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/reset_password_args.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_logo_header.dart';
import 'package:your_space_mobile/core/widgets/app_otp_input.dart';
import 'package:your_space_mobile/core/widgets/app_password_input.dart';

import '../cubit/reset_password_cubit/reset_password_cubit.dart';
import '../cubit/reset_password_cubit/reset_password_state.dart';

const _kResendCooldownSeconds = 30;

class ResetPasswordScreen extends StatefulWidget {
  final ResetPasswordArgs args;

  const ResetPasswordScreen({super.key, required this.args});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  Key _otpKey = UniqueKey();
  String _code = '';
  String? _otpError;
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  String? _newPasswordError;
  String? _confirmNewPasswordError;
  Timer? _cooldownTimer;
  int _resendSecondsLeft = _kResendCooldownSeconds;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendSecondsLeft = _kResendCooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSecondsLeft <= 1) {
        timer.cancel();
        setState(() => _resendSecondsLeft = 0);
      } else {
        setState(() => _resendSecondsLeft -= 1);
      }
    });
  }

  bool _validate() {
    final newPassword = _newPasswordController.text;
    final confirmNewPassword = _confirmNewPasswordController.text;
    setState(() {
      _otpError = _code.length < 6 ? 'auth.validation.otpIncomplete'.tr() : null;
      _newPasswordError =
          RegexHelper.validate(RegexHelper.accountPassword, newPassword) ? null : 'auth.passwordRule'.tr();
      _confirmNewPasswordError =
          confirmNewPassword == newPassword ? null : 'auth.validation.passwordMismatch'.tr();
    });
    return _otpError == null && _newPasswordError == null && _confirmNewPasswordError == null;
  }

  void _submit() {
    if (!_validate()) return;
    context.read<ResetPasswordCubit>().submit(
          email: widget.args.email,
          code: _code,
          newPassword: _newPasswordController.text,
          confirmNewPassword: _confirmNewPasswordController.text,
        );
  }

  void _resend() {
    if (_resendSecondsLeft > 0) return;
    _startCooldown();
    context.read<ResetPasswordCubit>().resendCode(email: widget.args.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<ResetPasswordCubit, ResetPasswordState>(
          listener: (context, state) {
            if (state is ResetPasswordSuccess) {
              context.go(AppRoutes.login);
              getIt<SnackBarHelper>().showSuccess('auth.resetPassword.doneMessage'.tr());
              return;
            }
            if (state is ResetPasswordError) {
              if (state.isNetworkError) {
                getIt<SnackBarHelper>().showError(
                  'common.networkError'.tr(),
                  actionLabel: 'common.retry'.tr(),
                  onAction: _submit,
                );
                return;
              }
              setState(() {
                _otpError = state.message;
                _otpKey = UniqueKey();
                _code = '';
              });
              return;
            }
            if (state is ResetPasswordResendError && state.isNetworkError) {
              getIt<SnackBarHelper>().showError(
                'common.networkError'.tr(),
                actionLabel: 'common.retry'.tr(),
                onAction: _resend,
              );
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogoHeader(compact: true),
                Text(
                  'auth.resetPassword.title'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 4.h),
                Text(
                  'auth.resetPassword.body'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 22.h),
                AppOtpInput(
                  key: _otpKey,
                  errorText: _otpError,
                  onChanged: (value) => _code = value,
                ),
                SizedBox(height: 14.h),
                Center(
                  child: _resendSecondsLeft <= 0
                      ? TextButton(
                          onPressed: _resend,
                          child: Text('auth.confirmEmail.resend'.tr()),
                        )
                      : Text(
                          '${'auth.confirmEmail.resendIn'.tr()} 0:${_resendSecondsLeft.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
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
                BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
                  builder: (context, state) => AppButton(
                    label: 'auth.resetPassword.submit'.tr(),
                    fullWidth: true,
                    loading: state is ResetPasswordSubmitting,
                    onPressed: _submit,
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

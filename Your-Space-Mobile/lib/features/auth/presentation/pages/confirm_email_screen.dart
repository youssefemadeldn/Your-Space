import 'dart:async';

// `hide TextDirection` — easy_localization re-exports intl's own TextDirection
// class (LTR/RTL/UNKNOWN), which would otherwise shadow Flutter's TextDirection
// (ltr/rtl) used for force-isolating the email substring under Arabic locale.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/confirm_email_args.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_logo_header.dart';
import 'package:your_space_mobile/core/widgets/app_otp_input.dart';

import '../cubit/confirm_email_cubit/confirm_email_cubit.dart';
import '../cubit/confirm_email_cubit/confirm_email_state.dart';

const _kResendCooldownSeconds = 30;

class ConfirmEmailScreen extends StatefulWidget {
  final ConfirmEmailArgs args;

  const ConfirmEmailScreen({super.key, required this.args});

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  Key _otpKey = UniqueKey();
  String _code = '';
  String? _otpError;
  bool _verified = false;
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

  void _verify() {
    if (_code.length < 6) {
      setState(() => _otpError = 'auth.validation.otpIncomplete'.tr());
      return;
    }
    setState(() => _otpError = null);
    context.read<ConfirmEmailCubit>().verify(email: widget.args.email, code: _code);
  }

  void _resend() {
    if (_resendSecondsLeft > 0) return;
    _startCooldown();
    context.read<ConfirmEmailCubit>().resendCode(email: widget.args.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<ConfirmEmailCubit, ConfirmEmailState>(
          listener: (context, state) {
            if (state is ConfirmEmailVerifySuccess) {
              setState(() => _verified = true);
              Future.delayed(const Duration(milliseconds: 1200), () {
                if (!context.mounted) return;
                context.go(AppRoutes.login);
                getIt<SnackBarHelper>().showSuccess('auth.confirmEmail.doneMessage'.tr());
              });
              return;
            }
            if (state is ConfirmEmailVerifyError) {
              if (state.isNetworkError) {
                getIt<SnackBarHelper>().showError(
                  'common.networkError'.tr(),
                  actionLabel: 'common.retry'.tr(),
                  onAction: _verify,
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
            if (state is ConfirmEmailResendError && state.isNetworkError) {
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
                  'auth.confirmEmail.title'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 4.h),
                Text.rich(
                  TextSpan(
                    style: AppTextStyles.bodyMedium,
                    children: [
                      TextSpan(text: '${'auth.confirmEmail.bodyPrefix'.tr()} '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            widget.args.email,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 22.h),
                if (!_verified) ...[
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
                            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textHint),
                          ),
                  ),
                  SizedBox(height: 14.h),
                  BlocBuilder<ConfirmEmailCubit, ConfirmEmailState>(
                    builder: (context, state) => AppButton(
                      label: 'auth.confirmEmail.verify'.tr(),
                      fullWidth: true,
                      loading: state is ConfirmEmailVerifying,
                      onPressed: _verify,
                    ),
                  ),
                ] else
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Column(
                      children: [
                        Container(
                          width: 72.w,
                          height: 72.w,
                          decoration: const BoxDecoration(
                            color: AppColors.tintSuccess,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_rounded, color: AppColors.success, size: 34.sp),
                        ),
                        SizedBox(height: 14.h),
                        Text('auth.confirmEmail.done'.tr(), style: Theme.of(context).textTheme.titleMedium),
                      ],
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

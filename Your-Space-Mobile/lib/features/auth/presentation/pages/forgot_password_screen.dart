// `hide TextDirection` — easy_localization re-exports intl's own TextDirection
// class (LTR/RTL/UNKNOWN), which would otherwise shadow Flutter's TextDirection
// (ltr/rtl) used for forcing LTR on the email field under Arabic locale.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/regex_helper.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/reset_password_args.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_logo_header.dart';

import '../cubit/forgot_password_cubit/forgot_password_cubit.dart';
import '../cubit/forgot_password_cubit/forgot_password_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final error = RegexHelper.validate(RegexHelper.email, email) ? null : 'auth.validation.invalidEmail'.tr();
    setState(() => _emailError = error);
    if (error != null) return;
    context.read<ForgotPasswordCubit>().submit(email: email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
          listener: (context, state) {
            if (state is ForgotPasswordSuccess) {
              setState(() => _sent = true);
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (!context.mounted) return;
                context.pushReplacementNamed(
                  AppRoutes.resetPassword,
                  extra: ResetPasswordArgs(email: _emailController.text.trim()),
                );
              });
              return;
            }
            if (state is ForgotPasswordError) {
              if (state.isNetworkError) {
                getIt<SnackBarHelper>().showError(
                  'common.networkError'.tr(),
                  actionLabel: 'common.retry'.tr(),
                  onAction: _submit,
                );
                return;
              }
              getIt<SnackBarHelper>().showError(state.message);
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogoHeader(compact: true),
                Text(
                  'auth.forgotPassword.title'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 4.h),
                Text(
                  'auth.forgotPassword.body'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 22.h),
                if (!_sent) ...[
                  AppInput(
                    label: 'auth.email'.tr(),
                    hintText: 'you@example.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    controller: _emailController,
                    errorText: _emailError,
                    onChanged: (_) {
                      if (_emailError != null) setState(() => _emailError = null);
                    },
                  ),
                  SizedBox(height: 20.h),
                  BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
                    builder: (context, state) => AppButton(
                      label: 'auth.forgotPassword.submit'.tr(),
                      fullWidth: true,
                      loading: state is ForgotPasswordLoading,
                      onPressed: _submit,
                    ),
                  ),
                ] else
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Column(
                      children: [
                        Container(
                          width: 72.w,
                          height: 72.w,
                          decoration: const BoxDecoration(
                            color: AppColors.brandRedSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 34.sp),
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          'auth.forgotPassword.sent'.tr(),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium,
                        ),
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

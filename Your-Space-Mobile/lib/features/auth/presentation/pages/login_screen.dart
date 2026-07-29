// `hide TextDirection` — easy_localization re-exports intl's own TextDirection
// class (LTR/RTL/UNKNOWN), which would otherwise shadow Flutter's TextDirection
// (ltr/rtl) used for forcing LTR on email/phone fields under Arabic locale.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/confirm_email_args.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_checkbox.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_logo_header.dart';
import 'package:your_space_mobile/core/widgets/app_password_input.dart';

import '../cubit/login_cubit/login_cubit.dart';
import '../cubit/login_cubit/login_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _passwordError = null);
    context.read<LoginCubit>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<LoginCubit, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              context.go(AppRoutes.home); // .go, not .pushNamed — replaces the auth stack
              return;
            }
            if (state is! LoginError) return;
            switch (state.errorCode) {
              case 'Auth.EmailNotConfirmed':
                context.pushNamed(
                  AppRoutes.confirmEmail,
                  extra: ConfirmEmailArgs(email: _emailController.text.trim()),
                );
              case 'Auth.InvalidCredentials':
                setState(() => _passwordError = 'auth.login.invalidCredentials'.tr());
              default:
                if (state.isNetworkError) {
                  getIt<SnackBarHelper>().showError(
                    'common.networkError'.tr(),
                    actionLabel: 'common.retry'.tr(),
                    onAction: _submit,
                  );
                } else {
                  getIt<SnackBarHelper>().showError(state.message);
                }
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogoHeader(),
                AppInput(
                  label: 'auth.email'.tr(),
                  hintText: 'you@example.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  controller: _emailController,
                ),
                SizedBox(height: 14.h),
                AppPasswordInput(
                  label: 'auth.password'.tr(),
                  controller: _passwordController,
                  errorText: _passwordError,
                  onChanged: (_) {
                    if (_passwordError != null) setState(() => _passwordError = null);
                  },
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left at its natural size — "Remember me" is short and
                    // fixed; only the link on the right needs to flex/shrink
                    // for a longer translation or narrower screen.
                    AppCheckbox(
                      checked: _rememberMe,
                      label: 'auth.login.remember'.tr(),
                      onChanged: (value) => setState(() => _rememberMe = value),
                    ),
                    Flexible(
                      child: TextButton(
                        onPressed: () => context.pushNamed(AppRoutes.forgotPassword),
                        child: Text('auth.login.forgot'.tr(), overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                BlocBuilder<LoginCubit, LoginState>(
                  builder: (context, state) => AppButton(
                    label: 'auth.login.submit'.tr(),
                    fullWidth: true,
                    loading: state is LoginLoading,
                    onPressed: _submit,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'auth.login.noAccount'.tr(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pushNamed(AppRoutes.register),
                      child: Text('auth.login.signUp'.tr()),
                    ),
                  ],
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

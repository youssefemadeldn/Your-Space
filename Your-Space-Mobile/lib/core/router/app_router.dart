import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/change_password_cubit/change_password_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/confirm_email_cubit/confirm_email_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/forgot_password_cubit/forgot_password_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/login_cubit/login_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/register_cubit/register_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/reset_password_cubit/reset_password_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/change_password_screen.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/confirm_email_screen.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/register_screen.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/reset_password_screen.dart';

import 'app_routes.dart';
import 'args/confirm_email_args.dart';
import 'args/reset_password_args.dart';

class AppRouter {
  AppRouter._();

  static Widget _unknown(GoRouterState state) => const _UnknownScreen();

  static GoRouter router(GlobalKey<NavigatorState> navigatorKey) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          redirect: (context, state) => AppRoutes.login,
        ),
        GoRoute(
          path: AppRoutes.login,
          name: AppRoutes.login,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<LoginCubit>(),
            child: const LoginScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: AppRoutes.register,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<RegisterCubit>(),
            child: const RegisterScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.confirmEmail,
          name: AppRoutes.confirmEmail,
          builder: (context, state) {
            final args = state.extra as ConfirmEmailArgs?;
            if (args == null) return _unknown(state);
            return BlocProvider(
              create: (_) => getIt<ConfirmEmailCubit>(),
              child: ConfirmEmailScreen(args: args),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          name: AppRoutes.forgotPassword,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<ForgotPasswordCubit>(),
            child: const ForgotPasswordScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          name: AppRoutes.resetPassword,
          builder: (context, state) {
            final args = state.extra as ResetPasswordArgs?;
            if (args == null) return _unknown(state);
            return BlocProvider(
              create: (_) => getIt<ResetPasswordCubit>(),
              child: ResetPasswordScreen(args: args),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.changePassword,
          name: AppRoutes.changePassword,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<ChangePasswordCubit>(),
            child: const ChangePasswordScreen(),
          ),
        ),
      ],
      errorBuilder: (context, state) => const _UnknownScreen(),
    );
  }
}

class _UnknownScreen extends StatelessWidget {
  const _UnknownScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Page not found')));
  }
}

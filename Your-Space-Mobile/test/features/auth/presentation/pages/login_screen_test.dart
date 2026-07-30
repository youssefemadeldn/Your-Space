import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/theme/app_theme.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_checkbox.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/login_cubit/login_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  // Merged into one testWidgets block — a second EasyLocalization
  // instantiation within the same test file breaks the widget tree (known
  // easy_localization test-infra issue, same as home_screen_test.dart /
  // invite_method_chip_group_test.dart).
  testWidgets('submits with the current Remember me state', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockAuthRepository();
    // Left(UnauthorizedFailure(errorCode: 'Auth.InvalidCredentials')), not
    // Right(...) — keeps the cubit out of LoginSuccess so the screen never
    // calls context.go(AppRoutes.home) (no real GoRouter in this harness),
    // and this specific errorCode is the one LoginScreen branch that only
    // calls setState — every other error branch reaches getIt<SnackBarHelper>(),
    // which isn't registered in this bare test environment.
    when(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          rememberMe: any(named: 'rememberMe'),
        )).thenAnswer((_) async => const Left(UnauthorizedFailure(errorCode: 'Auth.InvalidCredentials')));

    final cubit = LoginCubit(repository);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) => ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: BlocProvider<LoginCubit>.value(
                value: cubit,
                child: const LoginScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'a@a.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    // Remember me left unchecked (default) → submit forwards rememberMe: false.
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    verify(() => repository.login(email: 'a@a.com', password: 'password123', rememberMe: false)).called(1);

    // Check Remember me, then submit again → forwards rememberMe: true.
    await tester.tap(find.byType(AppCheckbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    verify(() => repository.login(email: 'a@a.com', password: 'password123', rememberMe: true)).called(1);
  });
}

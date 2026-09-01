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
import 'package:your_space_mobile/core/widgets/app_password_input.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/delete_account_cubit/delete_account_cubit.dart';
import 'package:your_space_mobile/features/settings/presentation/pages/settings_screen/settings_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  // One EasyLocalization instantiation per test file — a second breaks the tree and
  // leaves `.tr()` returning raw keys — so the whole flow lives in one testWidgets.
  testWidgets('renders the rows, opens the delete dialog, and shows a wrong-password error inline',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockAuthRepository();
    when(() => repository.deleteAccount(password: any(named: 'password'))).thenAnswer(
      (_) async => const Left(
        ValidationFailure(
          message: 'The password you entered is incorrect.',
          errorCode: 'Auth.DeleteAccount.InvalidPassword',
        ),
      ),
    );
    final cubit = DeleteAccountCubit(repository);
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
              home: BlocProvider<DeleteAccountCubit>.value(
                value: cubit,
                child: const SettingsScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // All three rows render.
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);

    // Tapping "Delete account" opens the password-confirm dialog.
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account?'), findsOneWidget);
    expect(find.byType(AppPasswordInput), findsOneWidget);
    expect(find.text('Delete my account'), findsOneWidget);

    // A wrong password keeps the dialog open with the backend message shown inline.
    await tester.enterText(find.byType(TextField), 'wrong-password');
    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();

    verify(() => repository.deleteAccount(password: 'wrong-password')).called(1);
    expect(find.text('The password you entered is incorrect.'), findsOneWidget);
    expect(find.text('Delete my account'), findsOneWidget);
    expect(find.byType(AppPasswordInput), findsOneWidget);
  });
}

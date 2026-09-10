import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/theme/app_theme.dart';
import 'package:your_space_mobile/core/widgets/app_password_input.dart';
import 'package:your_space_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/domain/use_cases/get_current_user_profile_use_case.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/delete_account_cubit/delete_account_cubit.dart';
import 'package:your_space_mobile/features/settings/presentation/cubit/profile_form_cubit/profile_form_cubit.dart';
import 'package:your_space_mobile/features/settings/presentation/pages/settings_screen/settings_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockGetCurrentUserProfileUseCase extends Mock implements GetCurrentUserProfileUseCase {}

class MockDataRefreshBus extends Mock implements DataRefreshBus {}

void main() {
  const profile = UserProfile(
    id: 'user-1',
    email: 'jane@example.com',
    firstName: 'Jane',
    lastName: 'Doe',
    phoneNumber: '+201234567890',
    gender: Gender.female,
    roles: ['User'],
  );

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
    final getCurrentUserProfile = MockGetCurrentUserProfileUseCase();
    when(() => getCurrentUserProfile()).thenAnswer((_) async => const Right(profile));
    when(() => repository.deleteAccount(password: any(named: 'password'))).thenAnswer(
      (_) async => const Left(
        ValidationFailure(
          message: 'The password you entered is incorrect.',
          errorCode: 'Auth.DeleteAccount.InvalidPassword',
        ),
      ),
    );

    final profileFormCubit = ProfileFormCubit(getCurrentUserProfile, repository, MockDataRefreshBus());
    addTearDown(profileFormCubit.close);
    final deleteAccountCubit = DeleteAccountCubit(repository);
    addTearDown(deleteAccountCubit.close);

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
              home: MultiBlocProvider(
                providers: [
                  BlocProvider<ProfileFormCubit>.value(value: profileFormCubit..initialize()),
                  BlocProvider<DeleteAccountCubit>.value(value: deleteAccountCubit),
                ],
                child: const SettingsScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The profile form prefills from the loaded profile.
    expect(find.text('Jane'), findsOneWidget);

    // All three account rows render.
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
    await tester.enterText(find.byType(TextField).last, 'wrong-password');
    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();

    verify(() => repository.deleteAccount(password: 'wrong-password')).called(1);
    expect(find.text('The password you entered is incorrect.'), findsOneWidget);
    expect(find.text('Delete my account'), findsOneWidget);
    expect(find.byType(AppPasswordInput), findsOneWidget);
  });
}

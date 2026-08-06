import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:your_space_mobile/core/theme/app_theme.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/register_cubit/register_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/register_screen/register_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Future<void> _pumpRegisterScreen(WidgetTester tester, RegisterCubit cubit) async {
  // The default 800x600 test surface doesn't represent any real phone and,
  // combined with ScreenUtil's scaling off a 390x844 design canvas, produces
  // spurious overflow/hit-test failures that never occur on an actual device.
  // Size the surface to the design canvas itself.
  //
  // `tester.binding.setSurfaceSize` only resizes the rendering surface — it
  // does not change what `MediaQuery.of(context).size` reports (still
  // 800x600 here), so ScreenUtil keeps scaling as if the screen were ~2x the
  // design width. `tester.view.physicalSize`/`devicePixelRatio` is what
  // actually changes MediaQuery's reported logical size.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
            home: BlocProvider<RegisterCubit>.value(
              value: cubit,
              child: const RegisterScreen(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('shows client-side validation errors when submitted empty', (tester) async {
    final cubit = RegisterCubit(MockAuthRepository());
    await _pumpRegisterScreen(tester, cubit);

    await tester.ensureVisible(find.byType(AppButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(find.text('Enter your first name'), findsOneWidget);
    expect(find.text('Enter your last name'), findsOneWidget);
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Enter a valid phone number, e.g. +201234567890'), findsOneWidget);

    await cubit.close();
  });
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:your_space_mobile/core/theme/app_theme.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/login_cubit/login_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/login_cubit/login_state.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// `Cubit.emit` is `@protected` — exposing it via a same-hierarchy subclass
/// (rather than calling it from the test file directly) keeps `flutter
/// analyze` clean while still letting the test drive specific states.
class _TestLoginCubit extends LoginCubit {
  _TestLoginCubit(super.repository);
  void emitTestState(LoginState state) => emit(state);
}

Future<void> _pumpLoginScreen(WidgetTester tester, _TestLoginCubit cubit) async {
  // The default 800x600 test surface doesn't represent any real phone and,
  // combined with ScreenUtil's scaling off a 390x844 design canvas, produces
  // spurious overflow in shared widgets (e.g. AppCheckbox) that never occurs
  // on an actual device. Size the surface to the design canvas itself.
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
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('renders email/password fields with no error initially', (tester) async {
    final cubit = _TestLoginCubit(MockAuthRepository());
    await _pumpLoginScreen(tester, cubit);

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Incorrect email or password'), findsNothing);

    await cubit.close();
  });

  testWidgets('shows the inline invalid-credentials error under the password field', (tester) async {
    final cubit = _TestLoginCubit(MockAuthRepository());
    await _pumpLoginScreen(tester, cubit);

    cubit.emitTestState(const LoginError('unused', errorCode: 'Auth.InvalidCredentials'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password'), findsOneWidget);

    await cubit.close();
  });
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Call once from each test file's `setUpAll` — mirrors the bootstrap
/// `test/widget_test.dart` already does before pumping anything wrapped in
/// EasyLocalization (which persists the selected locale via SharedPreferences).
Future<void> ensureTestHarnessReady() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
}

/// Wraps a widget under test with just ScreenUtilInit, since most
/// core/widgets only need `.w/.h/.r/.sp` at build time.
Widget wrapWithTestHarness(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: child),
    ),
  );
}

/// Pumps [child] wrapped via [wrapWithTestHarness] and settles — EasyLocalization
/// loads its translation asset asynchronously, so a bare `pumpWidget` leaves the
/// tree empty on the first frame; every test must settle before querying it.
Future<void> pumpTestHarness(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(wrapWithTestHarness(child));
  await tester.pumpAndSettle();
}

/// For widgets whose layout depends on real translated string lengths (e.g. a
/// tightly-fit `Row`/`Chip` sized around `.tr()` output) — [wrapWithTestHarness]
/// alone leaves `.tr()` unresolved (returns the raw key), which is often far
/// longer than the real translation and can overflow a layout that would never
/// overflow in the running app. Mirrors `register_screen_test.dart`'s pattern.
/// Also sizes the surface to the design canvas itself, since the default
/// 800x600 test surface's aspect ratio doesn't match any real phone and,
/// combined with ScreenUtil's `.w`/`.h` scaling off a 390x844 canvas, produces
/// spurious overflow that never occurs on an actual device.
Future<void> pumpTestHarnessWithLocalization(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

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
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(body: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

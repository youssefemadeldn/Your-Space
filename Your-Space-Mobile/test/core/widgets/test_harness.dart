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

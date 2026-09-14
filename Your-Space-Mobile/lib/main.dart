import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('en');
  await initializeDateFormatting('ar');
  await configureDependencies();

  // Eager warm-up: SyncService is @lazySingleton and nothing else in the
  // app is guaranteed to resolve it at startup. Touching it here is what
  // triggers its constructor (connectivity subscription + cold-start check,
  // design doc §5) — it is never awaited or referenced again after this.
  getIt<SyncService>();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(
        AppConstants.kDesignWidth,
        AppConstants.kDesignHeight,
      ),
      builder: (context, child) => MaterialApp.router(
        title: AppConstants.kAppName,
        debugShowCheckedModeBanner: false,
        routerConfig: getIt<GoRouter>(),
        theme: AppTheme.lightTheme,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      ),
    );
  }
}

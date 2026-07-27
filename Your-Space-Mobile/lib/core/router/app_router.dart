import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  // No feature screens exist yet — every location currently falls through to
  // errorBuilder. Add a GoRoute here (with its BlocProvider) as each screen
  // is built.
  static GoRouter router(GlobalKey<NavigatorState> navigatorKey) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: AppRoutes.splash,
      routes: const [],
      errorBuilder: (context, state) => const _UnknownScreen(),
    );
  }
}

class _UnknownScreen extends StatelessWidget {
  const _UnknownScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Page not found')),
    );
  }
}

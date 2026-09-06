import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/storage/app_preferences_helper.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';

import 'onboarding_dots_indicator.dart';
import 'onboarding_page_content.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    (
      icon: Icons.groups_rounded,
      titleKey: 'onboarding.page1Title',
      bodyKey: 'onboarding.page1Body',
    ),
    (
      icon: Icons.event_rounded,
      titleKey: 'onboarding.page2Title',
      bodyKey: 'onboarding.page2Body',
    ),
    (
      icon: Icons.history_rounded,
      titleKey: 'onboarding.page3Title',
      bodyKey: 'onboarding.page3Body',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await getIt<AppPreferencesHelper>().setSeenOnboarding();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _next() {
    if (_isLastPage) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Hidden entirely on the last page rather than just disabled —
            // there's nothing left to skip to once the flow is already done.
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: _isLastPage
                    ? SizedBox(height: 32.h)
                    : AppButton(
                        label: 'onboarding.skip'.tr(),
                        variant: AppButtonVariant.text,
                        size: AppButtonSize.sm,
                        onPressed: _finish,
                      ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  for (final page in _pages)
                    OnboardingPageContent(
                      icon: page.icon,
                      titleKey: page.titleKey,
                      bodyKey: page.bodyKey,
                    ),
                ],
              ),
            ),
            OnboardingDotsIndicator(pageCount: _pages.length, currentPage: _currentPage),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: AppButton(
                label: _isLastPage ? 'onboarding.getStarted'.tr() : 'onboarding.next'.tr(),
                fullWidth: true,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

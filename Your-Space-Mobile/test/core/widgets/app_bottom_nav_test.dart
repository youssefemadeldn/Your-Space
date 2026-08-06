import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/widgets/app_bottom_nav.dart';

import 'test_harness.dart';

void main() {
  setUpAll(ensureTestHarnessReady);

  // AppBottomNav mixes width-scaled icons with a height-scaled container —
  // the default 800x600 test surface has a very different aspect ratio than
  // the 390x844 design canvas, so ScreenUtil's independent .w/.h scale
  // factors overflow the row unless the surface is set to a phone-like
  // aspect ratio first (same gotcha documented in the Auth Flow handoff).
  void setPhoneLikeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('renders all 5 nav icons', (tester) async {
    setPhoneLikeSurface(tester);
    await pumpTestHarness(tester, AppBottomNav(currentIndex: 0, onTap: (_) {}));

    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
    expect(find.byIcon(Icons.people_alt_rounded), findsOneWidget);
    expect(find.byIcon(Icons.event_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
  });

  testWidgets('tapping a tab invokes onTap with its index — no GoRouter required', (tester) async {
    setPhoneLikeSurface(tester);
    int? tapped;
    await pumpTestHarness(
      tester,
      AppBottomNav(currentIndex: 0, onTap: (index) => tapped = index),
    );

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pump();

    expect(tapped, 4);
  });
}

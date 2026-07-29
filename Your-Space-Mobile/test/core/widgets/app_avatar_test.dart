import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/widgets/app_avatar.dart';

import 'test_harness.dart';

void main() {
  setUpAll(ensureTestHarnessReady);

  testWidgets('renders the first letters of a two-word name as initials', (tester) async {
    await pumpTestHarness(tester, const AppAvatar(name: 'Sara Adel'));

    expect(find.text('SA'), findsOneWidget);
  });

  testWidgets('renders only one initial for a single-word name', (tester) async {
    await pumpTestHarness(tester, const AppAvatar(name: 'Cher'));

    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('renders no initials for an empty name without throwing', (tester) async {
    await pumpTestHarness(tester, const AppAvatar(name: ''));

    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  testWidgets('same name always picks the same tone (deterministic)', (tester) async {
    await pumpTestHarness(
      tester,
      const Row(children: [AppAvatar(name: 'Omar Khaled'), AppAvatar(name: 'Omar Khaled')]),
    );

    final avatars = tester.widgetList<CircleAvatar>(find.byType(CircleAvatar)).toList();
    expect(avatars, hasLength(2));
    expect(avatars[0].backgroundColor, avatars[1].backgroundColor);
  });
}

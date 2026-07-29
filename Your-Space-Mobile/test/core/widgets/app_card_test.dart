import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';

import 'test_harness.dart';

void main() {
  setUpAll(ensureTestHarnessReady);

  testWidgets('renders its child', (tester) async {
    await pumpTestHarness(tester, const AppCard(child: Text('Card content')));

    expect(find.text('Card content'), findsOneWidget);
  });

  testWidgets('fires onTap when provided', (tester) async {
    var tapped = false;
    await pumpTestHarness(
      tester,
      AppCard(onTap: () => tapped = true, child: const Text('Tap me')),
    );

    await tester.tap(find.byType(AppCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('is not wrapped in InkWell when onTap is null', (tester) async {
    await pumpTestHarness(tester, const AppCard(child: Text('Static')));

    expect(find.byType(InkWell), findsNothing);
  });
}

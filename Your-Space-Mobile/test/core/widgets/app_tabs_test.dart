import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/widgets/app_tabs.dart';

import 'test_harness.dart';

void main() {
  setUpAll(ensureTestHarnessReady);

  testWidgets('renders every tab label', (tester) async {
    await pumpTestHarness(
      tester,
      AppTabs(tabs: const ['People', 'By group'], activeIndex: 0, onChanged: (_) {}),
    );

    expect(find.text('People'), findsOneWidget);
    expect(find.text('By group'), findsOneWidget);
  });

  testWidgets('tapping a tab invokes onChanged with its index', (tester) async {
    int? selected;
    await pumpTestHarness(
      tester,
      AppTabs(tabs: const ['People', 'By group'], activeIndex: 0, onChanged: (index) => selected = index),
    );

    await tester.tap(find.text('By group'));
    await tester.pump();

    expect(selected, 1);
  });
}

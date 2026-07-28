import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';

import 'test_harness.dart';

void main() {
  setUpAll(ensureTestHarnessReady);

  testWidgets('disables its tap handler when onPressed is null', (tester) async {
    await pumpTestHarness(
      tester,
      const AppButton(label: 'Disabled', onPressed: null),
    );

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });

  testWidgets('disables its tap handler while loading, even with onPressed set',
      (tester) async {
    var tapped = false;
    // Not pumpTestHarness/pumpAndSettle: the loading state's
    // CircularProgressIndicator animates indefinitely, so pumpAndSettle would
    // time out waiting for it to stop.
    await tester.pumpWidget(wrapWithTestHarness(
      AppButton(label: 'Loading', loading: true, onPressed: () => tapped = true),
    ));
    await tester.pump();

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);

    await tester.tap(find.byType(InkWell), warnIfMissed: false);
    await tester.pump();
    expect(tapped, isFalse);
  });

  testWidgets('fires onPressed when enabled and not loading', (tester) async {
    var tapped = false;
    await pumpTestHarness(
      tester,
      AppButton(label: 'Enabled', onPressed: () => tapped = true),
    );

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(tapped, isTrue);
  });
}

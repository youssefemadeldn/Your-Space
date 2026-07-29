import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/widgets/app_select.dart';

import 'test_harness.dart';

void main() {
  setUpAll(ensureTestHarnessReady);

  testWidgets('shows the placeholder when value is null', (tester) async {
    await pumpTestHarness(
      tester,
      AppSelect(
        value: null,
        placeholder: 'Choose a group',
        options: const ['Family', 'Close friends'],
        onChanged: (_) {},
      ),
    );

    expect(find.text('Choose a group'), findsOneWidget);
  });

  testWidgets('shows the selected value when set', (tester) async {
    await pumpTestHarness(
      tester,
      AppSelect(
        value: 'Family',
        options: const ['Family', 'Close friends'],
        onChanged: (_) {},
      ),
    );

    expect(find.text('Family'), findsOneWidget);
  });

  testWidgets('tapping opens a bottom sheet with every option, tapping one calls onChanged', (tester) async {
    String? selected;
    await pumpTestHarness(
      tester,
      AppSelect(
        value: null,
        placeholder: 'Choose a group',
        options: const ['Family', 'Close friends'],
        onChanged: (value) => selected = value,
      ),
    );

    await tester.tap(find.text('Choose a group'));
    await tester.pumpAndSettle();

    expect(find.text('Close friends'), findsOneWidget);
    await tester.tap(find.text('Close friends'));
    await tester.pumpAndSettle();

    expect(selected, 'Close friends');
  });

  testWidgets('disabled select does not open the picker', (tester) async {
    await pumpTestHarness(
      tester,
      AppSelect(
        value: null,
        placeholder: 'Choose a group',
        options: const ['Family'],
        enabled: false,
        onChanged: (_) {},
      ),
    );

    await tester.tap(find.text('Choose a group'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Family'), findsNothing);
  });
}

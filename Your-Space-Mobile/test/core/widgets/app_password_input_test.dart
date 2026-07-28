import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/widgets/app_password_input.dart';

import 'test_harness.dart';

void main() {
  setUpAll(ensureTestHarnessReady);

  testWidgets('starts obscured with the visibility icon shown', (tester) async {
    await pumpTestHarness(tester, const AppPasswordInput(label: 'Password'));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_rounded), findsNothing);
  });

  testWidgets(
      'toggling reveals the text and flips the icon, preserving entered text',
      (tester) async {
    await pumpTestHarness(tester, const AppPasswordInput(label: 'Password'));

    await tester.enterText(find.byType(TextField), 'sup3rSecret');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isFalse);
    expect(field.controller?.text, 'sup3rSecret');
    expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.visibility_rounded), findsNothing);
  });
}

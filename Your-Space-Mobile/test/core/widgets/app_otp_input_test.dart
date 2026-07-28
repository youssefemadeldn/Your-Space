import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/widgets/app_otp_input.dart';

import 'test_harness.dart';

void main() {
  Finder textFieldAt(int index) => find.byType(TextField).at(index);

  bool isFocused(WidgetTester tester, int index) {
    final field = tester.widget<TextField>(textFieldAt(index));
    return field.focusNode?.hasFocus ?? false;
  }

  String textAt(WidgetTester tester, int index) {
    final field = tester.widget<TextField>(textFieldAt(index));
    return field.controller?.text ?? '';
  }

  setUpAll(ensureTestHarnessReady);

  testWidgets('renders 6 digit boxes by default', (tester) async {
    await pumpTestHarness(tester, const AppOtpInput());

    expect(find.byType(TextField), findsNWidgets(6));
  });

  testWidgets('auto-advances focus to the next box on digit entry',
      (tester) async {
    await pumpTestHarness(tester, const AppOtpInput());

    await tester.enterText(textFieldAt(0), '1');
    await tester.pump();

    expect(isFocused(tester, 1), isTrue);
  });

  testWidgets(
      'moves focus back and clears the previous box on backspace when empty',
      (tester) async {
    await pumpTestHarness(tester, const AppOtpInput());

    await tester.enterText(textFieldAt(0), '1');
    await tester.pump();
    expect(isFocused(tester, 1), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(isFocused(tester, 0), isTrue);
    expect(textAt(tester, 0), isEmpty);
  });

  testWidgets('fires onChanged per keystroke and onCompleted with the full code',
      (tester) async {
    final changes = <String>[];
    String? completed;

    await pumpTestHarness(
      tester,
      AppOtpInput(
        onChanged: changes.add,
        onCompleted: (code) => completed = code,
      ),
    );

    for (var i = 0; i < 6; i++) {
      await tester.enterText(textFieldAt(i), '$i');
      await tester.pump();
    }

    expect(changes, isNotEmpty);
    expect(changes.last, '012345');
    expect(completed, '012345');
  });

  testWidgets(
      'reports the up-to-date code via onChanged after backspace clears the previous box',
      (tester) async {
    final changes = <String>[];

    await pumpTestHarness(tester, AppOtpInput(onChanged: changes.add));

    await tester.enterText(textFieldAt(0), '1');
    await tester.pump();
    await tester.enterText(textFieldAt(1), '2');
    await tester.pump();
    expect(isFocused(tester, 2), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(isFocused(tester, 1), isTrue);
    expect(textAt(tester, 1), isEmpty);

    final actualCode = List.generate(6, (i) => textAt(tester, i)).join();
    expect(changes.last, actualCode);
  });
}

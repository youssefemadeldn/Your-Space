import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/widgets/app_badge.dart';
import 'package:your_space_mobile/core/widgets/app_profile_row.dart';

import 'test_harness.dart';

void main() {
  setUpAll(ensureTestHarnessReady);

  testWidgets('renders name, group badge, and phone', (tester) async {
    await pumpTestHarness(
      tester,
      const AppProfileRow(
        name: 'Sara Adel',
        groupName: 'Family',
        phoneNumber: '+201001234567',
        trailing: AppBadge(label: 'Invited you'),
      ),
    );

    expect(find.text('Sara Adel'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('+201001234567'), findsOneWidget);
    expect(find.text('Invited you'), findsOneWidget);
  });

  testWidgets('omits the group/phone row entirely when both are null', (tester) async {
    await pumpTestHarness(
      tester,
      const AppProfileRow(name: 'Cher', trailing: Icon(Icons.chevron_right_rounded)),
    );

    expect(find.text('Cher'), findsOneWidget);
  });

  testWidgets('renders no trailing widget when trailing is null', (tester) async {
    await pumpTestHarness(tester, const AppProfileRow(name: 'Cher'));

    expect(find.text('Cher'), findsOneWidget);
  });

  testWidgets('fires onTap when provided', (tester) async {
    var tapped = false;
    await pumpTestHarness(
      tester,
      AppProfileRow(name: 'Sara Adel', onTap: () => tapped = true),
    );

    await tester.tap(find.byType(AppProfileRow));
    await tester.pump();

    expect(tapped, isTrue);
  });
}

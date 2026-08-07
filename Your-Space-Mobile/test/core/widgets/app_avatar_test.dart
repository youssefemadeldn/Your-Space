import 'package:cached_network_image/cached_network_image.dart';
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

  testWidgets('falls back to initials when photoUrl is empty', (tester) async {
    await pumpTestHarness(tester, const AppAvatar(name: 'Sara Adel', photoUrl: ''));

    expect(find.text('SA'), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('renders a CachedNetworkImage when photoUrl is provided', (tester) async {
    // Single pump only — a real/fake network fetch never resolves in this
    // sandboxed test environment, so pumpAndSettle would hang waiting on it.
    await tester.pumpWidget(wrapWithTestHarness(
      const AppAvatar(name: 'Sara Adel', photoUrl: 'https://example.com/avatar.jpg'),
    ));
    await tester.pump();

    final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(image.imageUrl, 'https://example.com/avatar.jpg');
  });
}

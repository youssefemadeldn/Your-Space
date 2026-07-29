import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/widgets/app_logo_header.dart';

import 'test_harness.dart';

void main() {
  setUpAll(ensureTestHarnessReady);

  testWidgets('renders the logo mark alongside the wordmark, centered by default', (tester) async {
    await pumpTestHarness(tester, const AppLogoHeader());

    expect(find.byType(SvgPicture), findsOneWidget);
    // The wordmark is a raw RichText (not a Text/Text.rich), so find.text
    // needs findRichText: true and the full concatenated plain text.
    expect(find.text('Your Space', findRichText: true), findsOneWidget);
    expect(find.byType(Center), findsWidgets);
  });

  testWidgets('centered: false aligns the lockup to the leading edge', (tester) async {
    await pumpTestHarness(
      tester,
      const AppLogoHeader(compact: true, centered: false, logoSize: 28),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    final align = tester.widget<Align>(find.byType(Align));
    expect(align.alignment, AlignmentDirectional.centerStart);
  });
}

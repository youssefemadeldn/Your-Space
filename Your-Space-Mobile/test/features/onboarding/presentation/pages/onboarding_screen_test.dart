import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/features/onboarding/presentation/pages/onboarding_screen/onboarding_screen.dart';

import '../../../../core/widgets/test_harness.dart';

void main() {
  setUpAll(ensureTestHarnessReady);

  testWidgets('walks through all 3 pages via Next, then shows Get started', (tester) async {
    await pumpTestHarnessWithLocalization(tester, const OnboardingScreen());

    expect(find.text('Your People, Organized'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Plan Events Without the Chaos'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Never Forget Who Invited You'), findsOneWidget);

    // Last page: primary button becomes "Get started", Skip disappears
    // (nothing left to skip to).
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });
}

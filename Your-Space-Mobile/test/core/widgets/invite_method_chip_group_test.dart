import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/entities/invite_method.dart';
import 'package:your_space_mobile/core/widgets/invite_method_chip_group.dart';

import 'test_harness.dart';

void main() {
  setUpAll(ensureTestHarnessReady);

  // Merged into one testWidgets block — a second EasyLocalization
  // instantiation within the same test file breaks the widget tree (known
  // easy_localization test-infra issue, documented in the Auth Flow handoff).
  testWidgets('renders a chip per InviteMethod and reports the tapped one', (tester) async {
    InviteMethod? selected;
    await pumpTestHarnessWithLocalization(
      tester,
      InviteMethodChipGroup(selected: null, onChanged: (method) => selected = method),
    );

    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Phone call'), findsOneWidget);
    expect(find.text('In person'), findsOneWidget);

    await tester.tap(find.text('Phone call'));
    await tester.pump();

    expect(selected, InviteMethod.phoneCall);
  });
}

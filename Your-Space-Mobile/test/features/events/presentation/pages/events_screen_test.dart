import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:your_space_mobile/core/mock/entities/event.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/core/theme/app_theme.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/events_list_cubit/events_list_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/events_list_cubit/events_list_state.dart';
import 'package:your_space_mobile/features/events/presentation/pages/events_screen.dart';

/// `Cubit.emit` is `@protected` and this project has no `bloc_test` dependency
/// (see the note in pubspec.yaml) to shortcut state injection — a subclass
/// exposing `emit` is the standard workaround.
class _TestEventsListCubit extends EventsListCubit {
  _TestEventsListCubit(super.store);
  void pushState(EventsListState state) => emit(state);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  // Merged into one testWidgets block — a second EasyLocalization
  // instantiation within the same test file breaks the widget tree (known
  // easy_localization test-infra issue, same as invite_method_chip_group_test.dart).
  testWidgets('renders the right branch for every EventsListState', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MockDataStore()..simulatedLatency = Duration.zero;
    final cubit = _TestEventsListCubit(store);
    addTearDown(cubit.close);

    cubit.pushState(const EventsListSuccess([]));
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) => ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: BlocProvider<EventsListCubit>.value(value: cubit, child: const EventsScreen()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Success, empty → empty state.
    expect(find.text('No events yet'), findsOneWidget);

    // Success, non-empty → event rows.
    final events = [
      Event(id: 1, name: "Sara's Birthday", totalGuestCount: 5, createdAt: DateTime(2026, 1, 1)),
    ];
    cubit.pushState(EventsListSuccess(events));
    await tester.pumpAndSettle();
    expect(find.text("Sara's Birthday"), findsOneWidget);

    // Error → error state with message.
    cubit.pushState(const EventsListError('Something went wrong'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorStateWidget), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);

    // Loading → loading indicator. Its CircularProgressIndicator animates
    // forever, so a single pump() is used instead of pumpAndSettle(), which
    // would never terminate.
    cubit.pushState(const EventsListLoading());
    // Bloc delivers the new state on the next microtask, not synchronously,
    // so a single pump() can land before the rebuild; two covers it reliably
    // without pumpAndSettle() (which never terminates against this state's
    // permanently-animating CircularProgressIndicator).
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });
}

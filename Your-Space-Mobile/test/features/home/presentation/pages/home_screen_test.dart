import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:your_space_mobile/core/theme/app_theme.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';
import 'package:your_space_mobile/features/auth/domain/use_cases/get_current_user_profile_use_case.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/home/presentation/cubit/home_stats_cubit/home_stats_cubit.dart';
import 'package:your_space_mobile/features/home/presentation/cubit/home_stats_cubit/home_stats_state.dart';
import 'package:your_space_mobile/features/home/presentation/pages/home_screen.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockPersonRepository extends Mock implements PersonRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockGetCurrentUserProfileUseCase extends Mock implements GetCurrentUserProfileUseCase {}

/// `Cubit.emit` is `@protected` and this project has no `bloc_test` dependency
/// (see the note in pubspec.yaml) to shortcut state injection — a subclass
/// exposing `emit` is the standard workaround, letting the test render a
/// state directly instead of depending on repository call timing.
class _TestHomeStatsCubit extends HomeStatsCubit {
  _TestHomeStatsCubit(
    super.groupRepository,
    super.personRepository,
    super.eventRepository,
    super.getCurrentUserProfile,
  );
  void pushState(HomeStatsState state) => emit(state);
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
  testWidgets('renders the right branch for every HomeStatsState', (tester) async {
    // AppBottomNav needs a phone-like aspect ratio to avoid spurious overflow —
    // same gotcha documented in app_bottom_nav_test.dart / register_screen_test.dart.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = _TestHomeStatsCubit(
      MockGroupRepository(),
      MockPersonRepository(),
      MockEventRepository(),
      MockGetCurrentUserProfileUseCase(),
    );
    addTearDown(cubit.close);

    cubit.pushState(
      const HomeStatsSuccess(groupsCount: 0, peopleCount: 0, eventsCount: 0, firstName: 'Jane'),
    );
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
              home: BlocProvider<HomeStatsCubit>.value(value: cubit, child: const HomeScreen()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No AppBar/logout here anymore — Settings owns logout now (Sprint 2).
    // The header shows the avatar-initials + personalized greeting instead.
    expect(find.widgetWithIcon(IconButton, Icons.logout_rounded), findsNothing);
    expect(find.text('Hi Jane'), findsOneWidget);

    // Success, groupsCount == 0 → empty state.
    expect(find.text('Start with one group'), findsOneWidget);

    // Success, groupsCount > 0 → stat content.
    cubit.pushState(
      const HomeStatsSuccess(groupsCount: 4, peopleCount: 10, eventsCount: 2, firstName: 'Jane'),
    );
    await tester.pumpAndSettle();
    // groupsCount/peopleCount each render twice: once in a stat AppCard, once
    // as an AppListTile subtitle. eventsCount only has the list tile.
    expect(find.text('4'), findsNWidgets(2));
    expect(find.text('10'), findsNWidgets(2));
    expect(find.text('2'), findsOneWidget);

    // Error → error state with message.
    cubit.pushState(const HomeStatsError('Something went wrong'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorStateWidget), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);

    // Loading → loading indicator. Its CircularProgressIndicator animates
    // forever, so a single pump() is used instead of pumpAndSettle(), which
    // would never terminate.
    cubit.pushState(const HomeStatsLoading());
    // Bloc delivers the new state on the next microtask, not synchronously,
    // so a single pump() can land before the rebuild; two covers it reliably
    // without pumpAndSettle() (which never terminates against this state's
    // permanently-animating CircularProgressIndicator).
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });
}

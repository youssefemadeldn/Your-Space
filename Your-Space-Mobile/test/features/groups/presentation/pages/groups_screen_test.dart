import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/theme/app_theme.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/group_action_cubit/group_action_cubit.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/groups_list_cubit/groups_list_cubit.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/groups_list_cubit/groups_list_state.dart';
import 'package:your_space_mobile/features/groups/presentation/pages/groups_screen/groups_screen.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

/// `Cubit.emit` is `@protected` and this project has no `bloc_test` dependency
/// (see the note in pubspec.yaml) to shortcut state injection — a subclass
/// exposing `emit` is the standard workaround.
class _TestGroupsListCubit extends GroupsListCubit {
  _TestGroupsListCubit(super.groupRepository, super.dataRefreshBus);
  void pushState(GroupsListState state) => emit(state);
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
  testWidgets('renders the right branch for every GroupsListState', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final groupRepository = MockGroupRepository();
    final dataRefreshBus = DataRefreshBus();
    final listCubit = _TestGroupsListCubit(groupRepository, dataRefreshBus);
    final actionCubit = GroupActionCubit(groupRepository, dataRefreshBus);
    addTearDown(listCubit.close);
    addTearDown(actionCubit.close);

    listCubit.pushState(const GroupsListSuccess([], pageIndex: 1, hasNextPage: false));
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
              home: MultiBlocProvider(
                providers: [
                  BlocProvider<GroupsListCubit>.value(value: listCubit),
                  BlocProvider<GroupActionCubit>.value(value: actionCubit),
                ],
                child: const GroupsScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Success, empty → empty state.
    expect(find.text('No groups yet'), findsOneWidget);

    // Success, non-empty → group rows.
    const groups = [
      Group(id: 1, name: 'Family'),
      Group(id: 2, name: 'Close friends'),
    ];
    listCubit.pushState(const GroupsListSuccess(groups, pageIndex: 1, hasNextPage: false));
    await tester.pumpAndSettle();
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Close friends'), findsOneWidget);

    // Error → error state with message.
    listCubit.pushState(const GroupsListError('Something went wrong'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorStateWidget), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);

    // Loading → loading indicator. Its CircularProgressIndicator animates
    // forever, so a single pump() is used instead of pumpAndSettle(), which
    // would never terminate.
    listCubit.pushState(const GroupsListLoading());
    // Bloc delivers the new state on the next microtask, not synchronously,
    // so a single pump() can land before the rebuild; two covers it reliably
    // without pumpAndSettle() (which never terminates against this state's
    // permanently-animating CircularProgressIndicator).
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });
}

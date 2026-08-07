import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/theme/app_theme.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/people_list_cubit/people_list_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/people_list_cubit/people_list_state.dart';
import 'package:your_space_mobile/features/people/presentation/pages/people_screen/people_screen.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

/// `Cubit.emit` is `@protected` and this project has no `bloc_test` dependency
/// (see the note in pubspec.yaml) to shortcut state injection — a subclass
/// exposing `emit` is the standard workaround.
class _TestPeopleListCubit extends PeopleListCubit {
  _TestPeopleListCubit(super.personRepository, super.groupRepository, super.dataRefreshBus);
  void pushState(PeopleListState state) => emit(state);
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
  testWidgets('renders the right branch for every PeopleListState', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = _TestPeopleListCubit(MockPersonRepository(), MockGroupRepository(), DataRefreshBus());
    addTearDown(cubit.close);

    cubit.pushState(const PeopleListSuccess(people: [], groups: [], pageIndex: 1, hasNextPage: false));
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
              home: BlocProvider<PeopleListCubit>.value(value: cubit, child: const PeopleScreen()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Success, empty → empty state.
    expect(find.text('Nobody in this group yet'), findsOneWidget);

    // Success, non-empty → person rows.
    const group = Group(id: 1, name: 'Family');
    const people = [
      Person(id: 1, name: 'Sara Adel', gender: Gender.female, groupId: 1, groupName: 'Family'),
    ];
    cubit.pushState(const PeopleListSuccess(people: people, groups: [group], pageIndex: 1, hasNextPage: false));
    await tester.pumpAndSettle();
    expect(find.text('Sara Adel'), findsOneWidget);

    // Error → error state with message.
    cubit.pushState(const PeopleListError('Something went wrong'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorStateWidget), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);

    // Loading → loading indicator. Its CircularProgressIndicator animates
    // forever, so a single pump() is used instead of pumpAndSettle(), which
    // would never terminate.
    cubit.pushState(const PeopleListLoading());
    // Bloc delivers the new state on the next microtask, not synchronously,
    // so a single pump() can land before the rebuild; two covers it reliably
    // without pumpAndSettle() (which never terminates against this state's
    // permanently-animating CircularProgressIndicator).
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });
}

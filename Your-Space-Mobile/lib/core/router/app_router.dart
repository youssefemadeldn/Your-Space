import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/storage/secure_storage_helper.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/change_password_cubit/change_password_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/confirm_email_cubit/confirm_email_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/forgot_password_cubit/forgot_password_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/login_cubit/login_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/register_cubit/register_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/reset_password_cubit/reset_password_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/change_password_screen.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/confirm_email_screen.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/register_screen/register_screen.dart';
import 'package:your_space_mobile/features/auth/presentation/pages/reset_password_screen.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_action_cubit/add_guests_action_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_list_cubit/add_guests_list_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_details_cubit/event_details_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_form_cubit/event_form_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_guest_action_cubit/event_guest_action_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_guests_list_cubit/event_guests_list_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/events_list_cubit/events_list_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/reciprocity_suggestions_cubit/reciprocity_suggestions_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/pages/add_guests_screen/add_guests_screen.dart';
import 'package:your_space_mobile/features/events/presentation/pages/event_details_screen/event_details_screen.dart';
import 'package:your_space_mobile/features/events/presentation/pages/event_form_screen.dart';
import 'package:your_space_mobile/features/events/presentation/pages/event_guests_screen/event_guests_screen.dart';
import 'package:your_space_mobile/features/events/presentation/pages/events_screen.dart';
import 'package:your_space_mobile/features/events/presentation/pages/reciprocity_suggestions_screen.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/group_action_cubit/group_action_cubit.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/groups_list_cubit/groups_list_cubit.dart';
import 'package:your_space_mobile/features/groups/presentation/pages/groups_screen/groups_screen.dart';
import 'package:your_space_mobile/features/home/presentation/cubit/home_stats_cubit/home_stats_cubit.dart';
import 'package:your_space_mobile/features/home/presentation/pages/home_screen.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/add_occasion_cubit/add_occasion_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/people_list_cubit/people_list_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_details_cubit/person_details_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_form_cubit/person_form_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/pages/people_screen/people_screen.dart';
import 'package:your_space_mobile/features/people/presentation/pages/person_details_screen/person_details_screen.dart';
import 'package:your_space_mobile/features/people/presentation/pages/person_form_screen.dart';

import 'app_routes.dart';
import 'session_redirect.dart';
import 'args/add_guests_args.dart';
import 'args/confirm_email_args.dart';
import 'args/event_details_args.dart';
import 'args/event_form_args.dart';
import 'args/event_guests_args.dart';
import 'args/person_details_args.dart';
import 'args/person_form_args.dart';
import 'args/reciprocity_suggestions_args.dart';
import 'args/reset_password_args.dart';

class AppRouter {
  AppRouter._();

  static Widget _unknown(GoRouterState state) => const _UnknownScreen();

  static GoRouter router(GlobalKey<NavigatorState> navigatorKey) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          redirect: (context, state) => resolveSplashRedirect(getIt<SecureStorageHelper>()),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: AppRoutes.login,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<LoginCubit>(),
            child: const LoginScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: AppRoutes.register,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<RegisterCubit>(),
            child: const RegisterScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.confirmEmail,
          name: AppRoutes.confirmEmail,
          builder: (context, state) {
            final args = state.extra as ConfirmEmailArgs?;
            if (args == null) return _unknown(state);
            return BlocProvider(
              create: (_) => getIt<ConfirmEmailCubit>(),
              child: ConfirmEmailScreen(args: args),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          name: AppRoutes.forgotPassword,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<ForgotPasswordCubit>(),
            child: const ForgotPasswordScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          name: AppRoutes.resetPassword,
          builder: (context, state) {
            final args = state.extra as ResetPasswordArgs?;
            if (args == null) return _unknown(state);
            return BlocProvider(
              create: (_) => getIt<ResetPasswordCubit>(),
              child: ResetPasswordScreen(args: args),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.changePassword,
          name: AppRoutes.changePassword,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<ChangePasswordCubit>(),
            child: const ChangePasswordScreen(),
          ),
        ),

        // --- Home ---
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.home,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<HomeStatsCubit>()..load(),
            child: const HomeScreen(),
          ),
        ),

        // --- Groups ---
        GoRoute(
          path: AppRoutes.groups,
          name: AppRoutes.groups,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => getIt<GroupsListCubit>()..load()),
              BlocProvider(create: (_) => getIt<GroupActionCubit>()),
            ],
            child: const GroupsScreen(),
          ),
        ),

        // --- People ---
        GoRoute(
          path: AppRoutes.people,
          name: AppRoutes.people,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<PeopleListCubit>()..load(),
            child: const PeopleScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.personForm,
          name: AppRoutes.personForm,
          builder: (context, state) {
            final args = state.extra as PersonFormArgs? ?? const PersonFormArgs();
            return BlocProvider(
              create: (_) => getIt<PersonFormCubit>()..initialize(args.personId),
              child: PersonFormScreen(args: args),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.personDetails,
          name: AppRoutes.personDetails,
          builder: (context, state) {
            final args = state.extra as PersonDetailsArgs?;
            if (args == null) return _unknown(state);
            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => getIt<PersonDetailsCubit>()..loadDetails(args.personId)),
                BlocProvider(create: (_) => getIt<AddOccasionCubit>()),
              ],
              child: PersonDetailsScreen(args: args),
            );
          },
        ),

        // --- Events ---
        GoRoute(
          path: AppRoutes.events,
          name: AppRoutes.events,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<EventsListCubit>()..load(),
            child: const EventsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.eventForm,
          name: AppRoutes.eventForm,
          builder: (context, state) {
            final args = state.extra as EventFormArgs? ?? const EventFormArgs();
            return BlocProvider(
              create: (_) => getIt<EventFormCubit>()..initialize(args.eventId),
              child: EventFormScreen(args: args),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.eventDetails,
          name: AppRoutes.eventDetails,
          builder: (context, state) {
            final args = state.extra as EventDetailsArgs?;
            if (args == null) return _unknown(state);
            return BlocProvider(
              create: (_) => getIt<EventDetailsCubit>()..loadDetails(args.eventId),
              child: EventDetailsScreen(args: args),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.eventGuests,
          name: AppRoutes.eventGuests,
          builder: (context, state) {
            final args = state.extra as EventGuestsArgs?;
            if (args == null) return _unknown(state);
            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => getIt<EventGuestsListCubit>()..load(args.eventId)),
                BlocProvider(create: (_) => getIt<EventGuestActionCubit>()),
              ],
              child: EventGuestsScreen(args: args),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.addGuests,
          name: AppRoutes.addGuests,
          builder: (context, state) {
            final args = state.extra as AddGuestsArgs?;
            if (args == null) return _unknown(state);
            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => getIt<AddGuestsListCubit>()..load(args.eventId)),
                BlocProvider(create: (_) => getIt<AddGuestsActionCubit>()),
              ],
              child: AddGuestsScreen(args: args),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.reciprocitySuggestions,
          name: AppRoutes.reciprocitySuggestions,
          builder: (context, state) {
            final args = state.extra as ReciprocitySuggestionsArgs?;
            if (args == null) return _unknown(state);
            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => getIt<ReciprocitySuggestionsCubit>()..load(args.eventId)),
                BlocProvider(create: (_) => getIt<AddGuestsActionCubit>()),
              ],
              child: ReciprocitySuggestionsScreen(args: args),
            );
          },
        ),
      ],
      errorBuilder: (context, state) => const _UnknownScreen(),
    );
  }
}

class _UnknownScreen extends StatelessWidget {
  const _UnknownScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Page not found')));
  }
}

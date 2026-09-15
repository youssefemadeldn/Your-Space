import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/features/auth/domain/use_cases/get_current_user_profile_use_case.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

import 'home_stats_state.dart';

@injectable
class HomeStatsCubit extends Cubit<HomeStatsState> {
  final GroupRepository _groupRepository;
  final PersonRepository _personRepository;
  final EventRepository _eventRepository;
  final GetCurrentUserProfileUseCase _getCurrentUserProfile;
  final DataRefreshBus _dataRefreshBus;
  late final StreamSubscription<DataScope> _refreshSubscription;

  HomeStatsCubit(
    this._groupRepository,
    this._personRepository,
    this._eventRepository,
    this._getCurrentUserProfile,
    this._dataRefreshBus,
  ) : super(const HomeStatsInitial()) {
    // Every scope shown on Home (counts + greeting/avatar) reacts the same way.
    _refreshSubscription = _dataRefreshBus.stream.listen((_) => refresh());
  }

  /// Counts come from each list endpoint's `totalItems` — fetching a single
  /// item per list is enough to read the total without pulling every row.
  /// The profile fetch (for the header's "Hi {firstName}" greeting) runs
  /// alongside the three count calls, not after them. No prior state exists
  /// yet, so a failed profile fetch (e.g. offline on a cold start) falls all
  /// the way back to an empty greeting rather than blanking the dashboard —
  /// see [_fetch].
  Future<void> load() async {
    emit(const HomeStatsLoading());
    emit(await _fetch(fallbackName: '', fallbackAvatarUrl: null));
  }

  /// Re-fetches without a `Loading` flash — triggered by [DataRefreshBus]
  /// when a mutation elsewhere (add a person, edit profile, ...) makes the
  /// already-built Home tab's stats stale. Unlike [load], a prior
  /// `HomeStatsSuccess` exists here, so a failed profile fetch falls back to
  /// its greeting instead of an empty one — a background refresh should
  /// never regress what's already on screen.
  Future<void> refresh() async {
    final current = state;
    if (current is! HomeStatsSuccess) return;
    emit(await _fetch(fallbackName: current.firstName, fallbackAvatarUrl: current.avatarUrl));
  }

  /// Groups/People are local-first (CLAUDE.md Architecture rule 7) — a local
  /// count can't fail the way a network call can. Events and the profile
  /// (Auth is never migrated, per CLAUDE.md) stay network-only; either one's
  /// failure is folded to a fallback instead of failing the whole fetch and
  /// blanking the dashboard for one flaky network-only piece.
  Future<HomeStatsSuccess> _fetch({required String fallbackName, required String? fallbackAvatarUrl}) async {
    final groupsCountFuture = _groupRepository.countGroups();
    final peopleCountFuture = _personRepository.countPersons();
    final eventsCountFuture = _eventRepository
        .getEvents(pageIndex: 1, pageSize: 1)
        .then((r) => r.fold((_) => 0, (page) => page.totalItems));
    final profileFuture = _getCurrentUserProfile();

    final groupsCount = await groupsCountFuture;
    final peopleCount = await peopleCountFuture;
    final eventsCount = await eventsCountFuture;
    final profileResult = await profileFuture;

    return profileResult.fold(
      (_) => HomeStatsSuccess(
        groupsCount: groupsCount,
        peopleCount: peopleCount,
        eventsCount: eventsCount,
        firstName: fallbackName,
        avatarUrl: fallbackAvatarUrl,
      ),
      (profile) => HomeStatsSuccess(
        groupsCount: groupsCount,
        peopleCount: peopleCount,
        eventsCount: eventsCount,
        firstName: profile.firstName,
        avatarUrl: profile.avatarUrl,
      ),
    );
  }

  @override
  Future<void> close() {
    _refreshSubscription.cancel();
    return super.close();
  }
}

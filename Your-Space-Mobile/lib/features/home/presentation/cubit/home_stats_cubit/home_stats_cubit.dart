import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

import 'home_stats_state.dart';

@injectable
class HomeStatsCubit extends Cubit<HomeStatsState> {
  final GroupRepository _groupRepository;
  final PersonRepository _personRepository;
  final EventRepository _eventRepository;

  HomeStatsCubit(this._groupRepository, this._personRepository, this._eventRepository)
      : super(const HomeStatsInitial());

  /// Counts come from each list endpoint's `totalItems` — fetching a single
  /// item per list is enough to read the total without pulling every row.
  Future<void> load() async {
    emit(const HomeStatsLoading());
    final results = await Future.wait<Either<Failure, int>>([
      _groupRepository
          .getGroups(pageIndex: 1, pageSize: 1)
          .then((r) => r.map((page) => page.totalItems)),
      _personRepository
          .getPersons(pageIndex: 1, pageSize: 1)
          .then((r) => r.map((page) => page.totalItems)),
      _eventRepository
          .getEvents(pageIndex: 1, pageSize: 1)
          .then((r) => r.map((page) => page.totalItems)),
    ]);

    final failure = results
        .map((r) => r.fold((f) => f, (_) => null))
        .firstWhere((f) => f != null, orElse: () => null);
    if (failure != null) {
      emit(HomeStatsError(core.failureToMessage(failure)));
      return;
    }

    emit(HomeStatsSuccess(
      groupsCount: results[0].fold((_) => 0, (count) => count),
      peopleCount: results[1].fold((_) => 0, (count) => count),
      eventsCount: results[2].fold((_) => 0, (count) => count),
    ));
  }
}

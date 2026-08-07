import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

import '../failure_messages.dart';
import 'person_details_state.dart';

@injectable
class PersonDetailsCubit extends Cubit<PersonDetailsState> {
  final PersonRepository _personRepository;
  final DataRefreshBus _dataRefreshBus;
  late final StreamSubscription<DataScope> _refreshSubscription;

  PersonDetailsCubit(this._personRepository, this._dataRefreshBus) : super(const PersonDetailsInitial()) {
    _refreshSubscription = _dataRefreshBus.stream.listen((scope) {
      if (scope == DataScope.people) refresh();
    });
  }

  Future<void> loadDetails(int personId) async {
    emit(const PersonDetailsLoading());
    final result = await _personRepository.getPersonById(personId);
    result.fold(
      (failure) => emit(PersonDetailsError(failureToMessage(failure))),
      (details) => emit(PersonDetailsSuccess(person: details.person, occasions: details.occasionHistory)),
    );
  }

  /// Re-fetches this same person without a `Loading` flash — triggered by
  /// [DataRefreshBus] when the person was edited via `PersonForm` (pushed on
  /// top of this screen) and the user popped back here. Keeps the last-good
  /// details on screen on a background failure.
  Future<void> refresh() async {
    final current = state;
    if (current is! PersonDetailsSuccess) return;
    final result = await _personRepository.getPersonById(current.person.id);
    result.fold(
      (_) {},
      (details) => emit(PersonDetailsSuccess(person: details.person, occasions: details.occasionHistory)),
    );
  }

  @override
  Future<void> close() {
    _refreshSubscription.cancel();
    return super.close();
  }
}

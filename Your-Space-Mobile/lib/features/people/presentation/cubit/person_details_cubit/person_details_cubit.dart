import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'person_details_state.dart';

@injectable
class PersonDetailsCubit extends Cubit<PersonDetailsState> {
  final MockDataStore _store;

  PersonDetailsCubit(this._store) : super(const PersonDetailsInitial());

  Future<void> loadDetails(int personId) async {
    emit(const PersonDetailsLoading());
    await Future.delayed(_store.simulatedLatency);
    final person = _store.personById(personId);
    if (person == null) {
      emit(PersonDetailsError('people.details.notFound'.tr()));
      return;
    }
    emit(PersonDetailsSuccess(person: person, occasions: _store.occasionHistory(personId)));
  }
}

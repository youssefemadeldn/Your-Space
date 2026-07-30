import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

import '../failure_messages.dart';
import 'person_details_state.dart';

@injectable
class PersonDetailsCubit extends Cubit<PersonDetailsState> {
  final PersonRepository _personRepository;

  PersonDetailsCubit(this._personRepository) : super(const PersonDetailsInitial());

  Future<void> loadDetails(int personId) async {
    emit(const PersonDetailsLoading());
    final result = await _personRepository.getPersonById(personId);
    result.fold(
      (failure) => emit(PersonDetailsError(failureToMessage(failure))),
      (details) => emit(PersonDetailsSuccess(person: details.person, occasions: details.occasionHistory)),
    );
  }
}

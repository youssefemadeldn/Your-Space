import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'person_form_state.dart';

/// Single cubit for both load+submit — mirrors `ResetPasswordCubit`'s
/// precedent for a full-navigation form with no simultaneous list.
@injectable
class PersonFormCubit extends Cubit<PersonFormState> {
  final MockDataStore _store;

  PersonFormCubit(this._store) : super(const PersonFormInitial());

  void initialize(int? personId) {
    final person = personId == null ? null : _store.personById(personId);
    emit(PersonFormReady(person: person, availableGroups: _store.groups()));
  }

  Future<void> submit({
    int? personId,
    required String name,
    String? phoneNumber,
    required int groupId,
  }) async {
    emit(const PersonFormSubmitting());
    await Future.delayed(_store.simulatedLatency);
    final person = personId == null
        ? _store.createPerson(name: name, phoneNumber: phoneNumber, groupId: groupId)
        : _store.updatePerson(id: personId, name: name, phoneNumber: phoneNumber, groupId: groupId);
    emit(PersonFormSuccess(person));
  }
}

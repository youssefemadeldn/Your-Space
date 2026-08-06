import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

import '../failure_messages.dart';
import 'person_form_state.dart';

/// Single cubit for both load+submit — mirrors `ResetPasswordCubit`'s
/// precedent for a full-navigation form with no simultaneous list.
@injectable
class PersonFormCubit extends Cubit<PersonFormState> {
  final PersonRepository _personRepository;
  final GroupRepository _groupRepository;

  PersonFormCubit(this._personRepository, this._groupRepository) : super(const PersonFormInitial());

  Future<void> initialize(int? personId) async {
    emit(const PersonFormLoading());
    final groupsResult = await _groupRepository.getGroups(pageIndex: 1, pageSize: 50);
    await groupsResult.fold(
      (failure) async => emit(PersonFormError(failureToMessage(failure))),
      (page) async {
        if (personId == null) {
          emit(PersonFormReady(availableGroups: page.items));
          return;
        }
        final personResult = await _personRepository.getPersonById(personId);
        personResult.fold(
          (failure) => emit(PersonFormError(failureToMessage(failure))),
          (details) => emit(PersonFormReady(person: details.person, availableGroups: page.items)),
        );
      },
    );
  }

  Future<void> submit({
    int? personId,
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    String? notes,
  }) async {
    emit(const PersonFormSubmitting());
    final result = personId == null
        ? await _personRepository.createPerson(
            name: name,
            phoneNumber: phoneNumber,
            phoneNumber2: phoneNumber2,
            gender: gender,
            groupId: groupId,
            notes: notes,
          )
        : await _personRepository.updatePerson(
            id: personId,
            name: name,
            phoneNumber: phoneNumber,
            phoneNumber2: phoneNumber2,
            gender: gender,
            groupId: groupId,
            notes: notes,
          );
    result.fold(
      (failure) => emit(PersonFormError(failureToMessage(failure))),
      (person) => emit(PersonFormSuccess(person)),
    );
  }
}

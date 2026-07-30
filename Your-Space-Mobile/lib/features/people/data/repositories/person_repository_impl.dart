import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/entities/person_details.dart';
import '../../domain/entities/person_occasion_history_entry.dart';
import '../../domain/repositories/base_person_repository.dart';
import '../datasources/person_remote_data_source_impl.dart';
import '../models/add_occasion_history_request.dart';
import '../models/create_person_request.dart';
import '../models/update_person_request.dart';

@LazySingleton(as: PersonRepository)
class PersonRepositoryImpl implements PersonRepository {
  final PersonRemoteDataSourceImpl _remote;

  PersonRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResult<Person>>> getPersons({
    int? groupId,
    String? search,
    required int pageIndex,
    required int pageSize,
  }) async {
    final result = await _remote.getPersons(
      groupId: groupId,
      search: search,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
    return result.fold(Left.new, (response) => Right(response.toResult((r) => r.toEntity())));
  }

  @override
  Future<Either<Failure, PersonDetails>> getPersonById(int id) async {
    final result = await _remote.getPersonById(id);
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, Person>> createPerson({
    required String name,
    String? phoneNumber,
    required int groupId,
  }) async {
    final result = await _remote.createPerson(
      CreatePersonRequest(name: name, phoneNumber: phoneNumber, groupId: groupId),
    );
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, Person>> updatePerson({
    required int id,
    required String name,
    String? phoneNumber,
    required int groupId,
  }) async {
    final result = await _remote.updatePerson(
      UpdatePersonRequest(id: id, name: name, phoneNumber: phoneNumber, groupId: groupId),
    );
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, PersonOccasionHistoryEntry>> addOccasionHistory({
    required int personId,
    required bool invitedMe,
    InviteMethod? inviteMethod,
    String? occasionName,
    DateTime? occasionDate,
    String? notes,
  }) async {
    final result = await _remote.addOccasionHistory(
      personId,
      AddOccasionHistoryRequest(
        invitedMe: invitedMe,
        inviteMethod: inviteMethod,
        occasionName: occasionName,
        occasionDate: occasionDate,
        notes: notes,
      ),
    );
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }
}

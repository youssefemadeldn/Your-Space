import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/entities/person_details.dart';
import '../../domain/entities/person_occasion_history_entry.dart';
import '../../domain/repositories/base_person_repository.dart';
import '../datasources/base_person_data_source.dart';
import '../datasources/person_local_data_source_impl.dart';
import '../models/add_occasion_history_request.dart';
import '../models/create_person_request.dart';
import '../models/update_person_request.dart';

@LazySingleton(as: PersonRepository)
class PersonRepositoryImpl implements PersonRepository {
  final BasePersonDataSource _remote;
  final PersonLocalDataSourceImpl _local;

  PersonRepositoryImpl(@Named('remote') this._remote, @Named('local') this._local);

  @override
  Future<Either<Failure, PaginatedResult<Person>>> getPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
    required int pageIndex,
    required int pageSize,
  }) async {
    final result = await _remote.getPersons(
      groupId: groupId,
      subGroupId: subGroupId,
      governorateId: governorateId,
      cityId: cityId,
      neighborhoodId: neighborhoodId,
      search: search,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
    return result.fold(Left.new, (response) => Right(response.toResult((r) => r.toEntity())));
  }

  @override
  Stream<List<Person>> watchPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
    required int limit,
  }) =>
      _local.watchPersons(
        groupId: groupId,
        subGroupId: subGroupId,
        governorateId: governorateId,
        cityId: cityId,
        neighborhoodId: neighborhoodId,
        search: search,
        limit: limit,
      );

  @override
  Future<int> countPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
  }) =>
      _local.countPersons(
        groupId: groupId,
        subGroupId: subGroupId,
        governorateId: governorateId,
        cityId: cityId,
        neighborhoodId: neighborhoodId,
        search: search,
      );

  @override
  Future<Either<Failure, Unit>> refreshPersons() async {
    const bulkPageSize = 100;
    // Defensive cap (~5000 rows) — this data shape is "hundreds of rows"
    // (design doc §1), never expected to trip.
    const maxPages = 50;
    final all = <Person>[];
    for (var page = 1; page <= maxPages; page++) {
      final result = await _remote.getPersons(pageIndex: page, pageSize: bulkPageSize);
      if (result.isLeft()) {
        return result.fold(Left.new, (_) => throw StateError('unreachable'));
      }
      final response = result.getOrElse(() => throw StateError('unreachable'));
      all.addAll(response.items.map((r) => r.toEntity()));
      if (response.pageIndex >= response.totalPages) break;
    }
    await _local.savePersons(all);
    return const Right(unit);
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
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    int? subGroupId,
    required int governorateId,
    int? cityId,
    int? neighborhoodId,
    String? notes,
  }) async {
    final result = await _remote.createPerson(
      CreatePersonRequest(
        name: name,
        phoneNumber: phoneNumber,
        phoneNumber2: phoneNumber2,
        gender: gender,
        groupId: groupId,
        subGroupId: subGroupId,
        governorateId: governorateId,
        cityId: cityId,
        neighborhoodId: neighborhoodId,
        notes: notes,
      ),
    );
    return result.fold<Future<Either<Failure, Person>>>(
      (failure) async => Left(failure),
      (response) async {
        final person = response.toEntity();
        // Design doc §3: mutations go straight to remote and, on success,
        // upsert into drift so the cache doesn't go stale until the next sync.
        await _local.savePerson(person);
        return Right(person);
      },
    );
  }

  @override
  Future<Either<Failure, Person>> updatePerson({
    required int id,
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    int? subGroupId,
    required int governorateId,
    int? cityId,
    int? neighborhoodId,
    String? notes,
  }) async {
    final result = await _remote.updatePerson(
      UpdatePersonRequest(
        id: id,
        name: name,
        phoneNumber: phoneNumber,
        phoneNumber2: phoneNumber2,
        gender: gender,
        groupId: groupId,
        subGroupId: subGroupId,
        governorateId: governorateId,
        cityId: cityId,
        neighborhoodId: neighborhoodId,
        notes: notes,
      ),
    );
    return result.fold<Future<Either<Failure, Person>>>(
      (failure) async => Left(failure),
      (response) async {
        final person = response.toEntity();
        await _local.savePerson(person);
        return Right(person);
      },
    );
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

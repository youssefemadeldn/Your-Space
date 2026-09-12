import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
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
  final SyncService _syncService;

  PersonRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
    this._syncService,
  );

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

  int _newTempPersonId() => -DateTime.now().microsecondsSinceEpoch;

  /// Builds the [Person] draft + JSON-encoded [CreatePersonRequest] payload
  /// and queues both via the outbox. Shared by [createPerson] and
  /// [createPersonAndSync] — only what happens after queuing differs.
  Future<(Person, int)> _queueCreate({
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
  }) async {
    final person = Person(
      id: _newTempPersonId(),
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      groupName: groupName,
      subGroupId: subGroupId,
      subGroupName: subGroupName,
      governorateId: governorateId,
      governorateName: governorateName,
      cityId: cityId,
      cityName: cityName,
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodName,
      notes: notes,
    );
    final payloadJson = jsonEncode(CreatePersonRequest(
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
    ).toJson());
    final rowId = await _local.queuePersonMutation(person: person, operation: 'create', payloadJson: payloadJson);
    return (person, rowId);
  }

  /// Shared by [updatePerson] and [updatePersonAndSync] — same split as
  /// [_queueCreate].
  Future<(Person, int)> _queueUpdate({
    required int id,
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
  }) async {
    final person = Person(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      groupName: groupName,
      subGroupId: subGroupId,
      subGroupName: subGroupName,
      governorateId: governorateId,
      governorateName: governorateName,
      cityId: cityId,
      cityName: cityName,
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodName,
      notes: notes,
    );
    final payloadJson = jsonEncode(UpdatePersonRequest(
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
    ).toJson());
    final rowId = await _local.queuePersonMutation(person: person, operation: 'update', payloadJson: payloadJson);
    return (person, rowId);
  }

  @override
  Future<Either<Failure, Person>> createPerson({
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
  }) async {
    final (person, _) = await _queueCreate(
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      groupName: groupName,
      subGroupId: subGroupId,
      subGroupName: subGroupName,
      governorateId: governorateId,
      governorateName: governorateName,
      cityId: cityId,
      cityName: cityName,
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodName,
      notes: notes,
    );
    return Right(person);
  }

  @override
  Future<Either<Failure, Person>> updatePerson({
    required int id,
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
  }) async {
    final (person, _) = await _queueUpdate(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      groupName: groupName,
      subGroupId: subGroupId,
      subGroupName: subGroupName,
      governorateId: governorateId,
      governorateName: governorateName,
      cityId: cityId,
      cityName: cityName,
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodName,
      notes: notes,
    );
    return Right(person);
  }

  @override
  Future<Either<Failure, Person>> createPersonAndSync({
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
  }) async {
    final (person, rowId) = await _queueCreate(
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      groupName: groupName,
      subGroupId: subGroupId,
      subGroupName: subGroupName,
      governorateId: governorateId,
      governorateName: governorateName,
      cityId: cityId,
      cityName: cityName,
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodName,
      notes: notes,
    );
    final result = await _syncService.replayRow(rowId);
    return result.fold(Left.new, (payload) => Right(payload as Person? ?? person));
  }

  @override
  Future<Either<Failure, Person>> updatePersonAndSync({
    required int id,
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
  }) async {
    final (person, rowId) = await _queueUpdate(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      groupName: groupName,
      subGroupId: subGroupId,
      subGroupName: subGroupName,
      governorateId: governorateId,
      governorateName: governorateName,
      cityId: cityId,
      cityName: cityName,
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodName,
      notes: notes,
    );
    final result = await _syncService.replayRow(rowId);
    return result.fold(Left.new, (payload) => Right(payload as Person? ?? person));
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

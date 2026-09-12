import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';

/// Drift-backed local store for People — the Tier 1 read path (CLAUDE.md
/// Architecture rule 7). Does not implement `BasePersonDataSource`: it's
/// typed concretely in `PersonRepositoryImpl` so its `save*` write methods
/// (no remote equivalent) are reachable.
@Named('local')
@lazySingleton
class PersonLocalDataSourceImpl {
  final AppDatabase _db;

  PersonLocalDataSourceImpl(this._db);

  /// Reactive read path. `limit` grows as `loadMore()` is called on the
  /// caller side; this always queries from row 0 (no offset) rather than
  /// tracking a separate page window.
  Stream<List<Person>> watchPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
    required int limit,
  }) {
    final query = _db.select(_db.personsTable)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit);
    _applySelectFilters(
      query,
      groupId: groupId,
      subGroupId: subGroupId,
      governorateId: governorateId,
      cityId: cityId,
      neighborhoodId: neighborhoodId,
      search: search,
    );
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// One-shot exact count for the same filter set — backs `hasNextPage`
  /// without a `length == limit` heuristic.
  Future<int> countPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
  }) {
    final countExp = _db.personsTable.id.count();
    final query = _db.selectOnly(_db.personsTable)..addColumns([countExp]);
    query.where(_db.personsTable.isDeleted.equals(false));
    _applySelectOnlyFilters(
      query,
      groupId: groupId,
      subGroupId: subGroupId,
      governorateId: governorateId,
      cityId: cityId,
      neighborhoodId: neighborhoodId,
      search: search,
    );
    return query.map((row) => row.read(countExp) ?? 0).getSingle();
  }

  /// No remote equivalent — bulk-replaces the cache after a successful
  /// `refreshPersons()` fetch. One drift transaction.
  Future<void> savePersons(List<Person> people) => _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(
          _db.personsTable,
          people.map(_toCompanion).toList(),
        ),
      );

  /// No remote equivalent — single-row upsert after a successful
  /// create/update mutation (design doc §3: mutations go straight to remote
  /// and, on success, upsert into drift so the cache doesn't go stale).
  Future<void> savePerson(Person person) =>
      _db.into(_db.personsTable).insertOnConflictUpdate(_toCompanion(person));

  // Duplicated (rather than shared via a generic helper) because
  // `select()`/`SimpleSelectStatement` and `selectOnly()`/`SelectOnly` have
  // different `.where()` signatures in drift — fighting that generically
  // costs more than these six lines twice.
  void _applySelectFilters(
    SimpleSelectStatement<$PersonsTableTable, PersonsTableData> q, {
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
  }) {
    if (groupId != null) q.where((t) => t.groupId.equals(groupId));
    if (subGroupId != null) q.where((t) => t.subGroupId.equals(subGroupId));
    if (governorateId != null) q.where((t) => t.governorateId.equals(governorateId));
    if (cityId != null) q.where((t) => t.cityId.equals(cityId));
    if (neighborhoodId != null) q.where((t) => t.neighborhoodId.equals(neighborhoodId));
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      q.where(
        (t) => t.name.like(pattern) | t.phoneNumber.like(pattern) | t.phoneNumber2.like(pattern),
      );
    }
  }

  void _applySelectOnlyFilters(
    JoinedSelectStatement<$PersonsTableTable, PersonsTableData> q, {
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
  }) {
    final t = _db.personsTable;
    if (groupId != null) q.where(t.groupId.equals(groupId));
    if (subGroupId != null) q.where(t.subGroupId.equals(subGroupId));
    if (governorateId != null) q.where(t.governorateId.equals(governorateId));
    if (cityId != null) q.where(t.cityId.equals(cityId));
    if (neighborhoodId != null) q.where(t.neighborhoodId.equals(neighborhoodId));
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      q.where(t.name.like(pattern) | t.phoneNumber.like(pattern) | t.phoneNumber2.like(pattern));
    }
  }

  Person _toEntity(PersonsTableData row) => Person(
        id: row.id,
        name: row.name,
        phoneNumber: row.phoneNumber,
        phoneNumber2: row.phoneNumber2,
        gender: Gender.fromWire(row.gender),
        groupId: row.groupId,
        groupName: row.groupName,
        subGroupId: row.subGroupId,
        subGroupName: row.subGroupName,
        governorateId: row.governorateId,
        governorateName: row.governorateName,
        cityId: row.cityId,
        cityName: row.cityName,
        neighborhoodId: row.neighborhoodId,
        neighborhoodName: row.neighborhoodName,
        primaryPhotoUrl: row.primaryPhotoUrl,
        notes: row.notes,
        hasReciprocityHistory: row.hasReciprocityHistory,
      );

  PersonsTableCompanion _toCompanion(Person person) => PersonsTableCompanion.insert(
        id: Value(person.id),
        name: person.name,
        phoneNumber: Value(person.phoneNumber),
        phoneNumber2: Value(person.phoneNumber2),
        gender: person.gender.toWire(),
        groupId: person.groupId,
        groupName: person.groupName,
        subGroupId: Value(person.subGroupId),
        subGroupName: Value(person.subGroupName),
        governorateId: person.governorateId,
        governorateName: person.governorateName,
        cityId: Value(person.cityId),
        cityName: Value(person.cityName),
        neighborhoodId: Value(person.neighborhoodId),
        neighborhoodName: Value(person.neighborhoodName),
        primaryPhotoUrl: Value(person.primaryPhotoUrl),
        notes: Value(person.notes),
        hasReciprocityHistory: Value(person.hasReciprocityHistory),
        // Backend doesn't expose `UpdatedAt` yet (design doc §6/§11 row 5);
        // this row always comes from a just-completed, confirmed remote
        // round trip, so it's clean — never soft-deleted, never dirty.
        updatedAt: const Value(null),
        isDeleted: const Value(false),
        isDirty: const Value(false),
      );
}

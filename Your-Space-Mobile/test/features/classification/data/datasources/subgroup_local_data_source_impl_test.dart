import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/features/classification/data/datasources/subgroup_local_data_source_impl.dart';

void main() {
  late AppDatabase database;
  late SubGroupLocalDataSourceImpl dataSource;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = SubGroupLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('watchSubGroups emits the seeded set and reacts to a later saveSubGroup call', () async {
    await dataSource.saveSubGroups(const [
      SubGroup(id: 1, groupId: 7, name: 'Immediate Family'),
      SubGroup(id: 2, groupId: 7, name: 'Extended Family'),
    ]);

    final emissions = <List<SubGroup>>[];
    final subscription = dataSource.watchSubGroups(groupId: 7, limit: 10).listen(emissions.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(emissions, hasLength(1));
    expect(
      emissions.single,
      containsAll(const [
        SubGroup(id: 1, groupId: 7, name: 'Immediate Family'),
        SubGroup(id: 2, groupId: 7, name: 'Extended Family'),
      ]),
    );

    await dataSource.saveSubGroup(const SubGroup(id: 3, groupId: 7, name: 'Cousins'));
    await pumpEventQueue();

    expect(emissions.last, hasLength(3));
  });

  test('watchSubGroups filters strictly by groupId', () async {
    await dataSource.saveSubGroups(const [
      SubGroup(id: 1, groupId: 7, name: 'Immediate Family'),
      SubGroup(id: 2, groupId: 8, name: 'University Friends'),
    ]);

    final subGroups = await dataSource.watchSubGroups(groupId: 7, limit: 10).first;

    expect(subGroups.map((s) => s.id), [1]);
  });

  test('watchAllSubGroups is parent-agnostic', () async {
    await dataSource.saveSubGroups(const [
      SubGroup(id: 1, groupId: 7, name: 'Immediate Family'),
      SubGroup(id: 2, groupId: 8, name: 'University Friends'),
    ]);

    final subGroups = await dataSource.watchAllSubGroups(limit: 10).first;

    expect(subGroups.map((s) => s.id), containsAll([1, 2]));
  });

  test('saveSubGroup upserts rather than duplicates an existing id', () async {
    await dataSource.saveSubGroup(const SubGroup(id: 1, groupId: 7, name: 'Immediate Family'));
    await dataSource.saveSubGroup(const SubGroup(id: 1, groupId: 7, name: 'Immediate Family (Renamed)'));

    final subGroups = await dataSource.watchSubGroups(groupId: 7, limit: 10).first;

    expect(subGroups, const [SubGroup(id: 1, groupId: 7, name: 'Immediate Family (Renamed)')]);
  });

  test('search matches name and nameAr independently', () async {
    await dataSource.saveSubGroups(const [
      SubGroup(id: 1, groupId: 7, name: 'Immediate Family', nameAr: 'العائلة المباشرة'),
      SubGroup(id: 2, groupId: 7, name: 'University Friends'),
    ]);

    expect(
      (await dataSource.watchSubGroups(groupId: 7, search: 'immediate', limit: 10).first).map((s) => s.id),
      [1],
    );
    expect(
      (await dataSource.watchSubGroups(groupId: 7, search: 'العائلة المباشرة', limit: 10).first).map((s) => s.id),
      [1],
    );
    expect(
      (await dataSource.watchSubGroups(groupId: 7, search: 'university', limit: 10).first).map((s) => s.id),
      [2],
    );
  });

  test('limit truncates the result set', () async {
    await dataSource.saveSubGroups([for (var i = 1; i <= 5; i++) SubGroup(id: i, groupId: 7, name: 'SubGroup $i')]);

    final subGroups = await dataSource.watchSubGroups(groupId: 7, limit: 2).first;

    expect(subGroups, hasLength(2));
  });

  test('countSubGroups matches the unlimited watchSubGroups length and respects search', () async {
    await dataSource.saveSubGroups(const [
      SubGroup(id: 1, groupId: 7, name: 'Immediate Family'),
      SubGroup(id: 2, groupId: 7, name: 'University Friends'),
      SubGroup(id: 3, groupId: 7, name: 'Book club'),
    ]);

    expect(await dataSource.countSubGroups(groupId: 7), 3);
    expect(await dataSource.countSubGroups(groupId: 7, search: 'club'), 1);
  });

  test('deleteSubGroupLocal hard-removes the row', () async {
    await dataSource.saveSubGroup(const SubGroup(id: 1, groupId: 7, name: 'Immediate Family'));

    await dataSource.deleteSubGroupLocal(1);

    final subGroups = await dataSource.watchSubGroups(groupId: 7, limit: 10).first;
    expect(subGroups, isEmpty);
  });
}

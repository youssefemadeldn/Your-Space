import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/features/people/data/datasources/person_local_data_source_impl.dart';

Person _person({
  required int id,
  String name = 'Person',
  String? phoneNumber,
  String? phoneNumber2,
  int groupId = 1,
  int? subGroupId,
  int governorateId = 1,
  int? cityId,
  int? neighborhoodId,
}) =>
    Person(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: Gender.male,
      groupId: groupId,
      groupName: 'Group $groupId',
      subGroupId: subGroupId,
      subGroupName: subGroupId == null ? null : 'SubGroup $subGroupId',
      governorateId: governorateId,
      governorateName: 'Governorate $governorateId',
      cityId: cityId,
      cityName: cityId == null ? null : 'City $cityId',
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodId == null ? null : 'Neighborhood $neighborhoodId',
    );

void main() {
  late AppDatabase database;
  late PersonLocalDataSourceImpl dataSource;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = PersonLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('watchPersons emits the seeded set and reacts to a later savePerson call', () async {
    await dataSource.savePersons([_person(id: 1, name: 'Alice'), _person(id: 2, name: 'Bob')]);

    final emissions = <List<Person>>[];
    final subscription = dataSource.watchPersons(limit: 10).listen(emissions.add);
    addTearDown(subscription.cancel);

    // Let the initial query flush before mutating — drift schedules its
    // watch notifications asynchronously, so a write issued too close to
    // subscribing can coalesce with the first emission instead of producing
    // a distinct second one.
    await pumpEventQueue();
    expect(emissions, hasLength(1));
    expect(emissions.single, containsAll([_person(id: 1, name: 'Alice'), _person(id: 2, name: 'Bob')]));

    await dataSource.savePerson(_person(id: 3, name: 'Cara'));
    await pumpEventQueue();

    expect(emissions.last, hasLength(3));
    expect(
      emissions.last,
      containsAll([_person(id: 1, name: 'Alice'), _person(id: 2, name: 'Bob'), _person(id: 3, name: 'Cara')]),
    );
  });

  test('savePerson/savePersons upsert rather than duplicate an existing id', () async {
    await dataSource.savePerson(_person(id: 1, name: 'Alice'));
    await dataSource.savePerson(_person(id: 1, name: 'Alice Updated'));

    final people = await dataSource.watchPersons(limit: 10).first;

    expect(people, [_person(id: 1, name: 'Alice Updated')]);
  });

  test('each of the 5 filter dimensions filters correctly, alone and combined', () async {
    await dataSource.savePersons([
      _person(id: 1, groupId: 1, subGroupId: 10, governorateId: 100, cityId: 1000, neighborhoodId: 10000),
      _person(id: 2, groupId: 2, subGroupId: 20, governorateId: 100, cityId: 1000, neighborhoodId: 10000),
      _person(id: 3, groupId: 1, subGroupId: 11, governorateId: 200, cityId: 2000, neighborhoodId: 20000),
    ]);

    expect((await dataSource.watchPersons(groupId: 1, limit: 10).first).map((p) => p.id), [1, 3]);
    expect((await dataSource.watchPersons(subGroupId: 20, limit: 10).first).map((p) => p.id), [2]);
    expect((await dataSource.watchPersons(governorateId: 200, limit: 10).first).map((p) => p.id), [3]);
    expect((await dataSource.watchPersons(cityId: 1000, limit: 10).first).map((p) => p.id), [1, 2]);
    expect((await dataSource.watchPersons(neighborhoodId: 20000, limit: 10).first).map((p) => p.id), [3]);
    expect(
      (await dataSource.watchPersons(groupId: 1, governorateId: 100, limit: 10).first).map((p) => p.id),
      [1],
    );
  });

  test('search matches name, phoneNumber, and phoneNumber2 independently', () async {
    await dataSource.savePersons([
      _person(id: 1, name: 'Nadia Kamal'),
      _person(id: 2, name: 'Other', phoneNumber: '0100000001'),
      _person(id: 3, name: 'Other2', phoneNumber2: '0100000002'),
    ]);

    expect((await dataSource.watchPersons(search: 'nadia', limit: 10).first).map((p) => p.id), [1]);
    expect((await dataSource.watchPersons(search: '0100000001', limit: 10).first).map((p) => p.id), [2]);
    expect((await dataSource.watchPersons(search: '0100000002', limit: 10).first).map((p) => p.id), [3]);
  });

  test('limit truncates the result set', () async {
    await dataSource.savePersons([for (var i = 1; i <= 5; i++) _person(id: i, name: 'Person $i')]);

    final people = await dataSource.watchPersons(limit: 2).first;

    expect(people, hasLength(2));
  });

  test('countPersons matches the unlimited watchPersons length and respects filters', () async {
    await dataSource.savePersons([
      _person(id: 1, groupId: 1),
      _person(id: 2, groupId: 1),
      _person(id: 3, groupId: 2),
    ]);

    expect(await dataSource.countPersons(), 3);
    expect(await dataSource.countPersons(groupId: 1), 2);
  });
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/features/groups/data/datasources/group_local_data_source_impl.dart';
import 'package:your_space_mobile/features/groups/data/datasources/group_remote_data_source_impl.dart';
import 'package:your_space_mobile/features/groups/data/models/create_group_request.dart';
import 'package:your_space_mobile/features/groups/data/models/group_response.dart';
import 'package:your_space_mobile/features/groups/data/models/update_group_request.dart';
import 'package:your_space_mobile/features/groups/data/repositories/group_repository_impl.dart';

class MockGroupRemoteDataSourceImpl extends Mock implements GroupRemoteDataSourceImpl {}

class MockGroupLocalDataSourceImpl extends Mock implements GroupLocalDataSourceImpl {}

void main() {
  late MockGroupRemoteDataSourceImpl remote;
  late MockGroupLocalDataSourceImpl local;
  late GroupRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const CreateGroupRequest(name: ''));
    registerFallbackValue(const UpdateGroupRequest(id: 0, name: ''));
    registerFallbackValue(const Group(id: 0, name: ''));
  });

  setUp(() {
    remote = MockGroupRemoteDataSourceImpl();
    local = MockGroupLocalDataSourceImpl();
    repository = GroupRepositoryImpl(remote, local);
    when(() => local.saveGroup(any())).thenAnswer((_) async {});
  });

  test('getGroups maps a paginated response to a PaginatedResult of entities', () async {
    when(() => remote.getGroups(search: any(named: 'search'), pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResponse(
        items: [GroupResponse(id: 1, name: 'Family'), GroupResponse(id: 2, name: 'Close friends')],
        pageIndex: 1,
        totalPages: 1,
        totalItems: 2,
      )),
    );

    final result = await repository.getGroups(pageIndex: 1, pageSize: 20);

    expect(result.isRight(), isTrue);
    final page = result.getOrElse(() => throw StateError('expected Right'));
    expect(page.items.map((g) => g.name), ['Family', 'Close friends']);
    expect(page.totalItems, 2);
  });

  test('getGroups propagates a failure unchanged', () async {
    const failure = NetworkFailure();
    when(() => remote.getGroups(search: any(named: 'search'), pageIndex: 1, pageSize: 20))
        .thenAnswer((_) async => const Left(failure));

    final result = await repository.getGroups(pageIndex: 1, pageSize: 20);

    expect(result, const Left(failure));
  });

  test('createGroup maps the response to an entity and saves it locally', () async {
    when(() => remote.createGroup(any()))
        .thenAnswer((_) async => const Right(GroupResponse(id: 5, name: 'Book club')));

    final result = await repository.createGroup(name: 'Book club');

    expect(result, const Right(Group(id: 5, name: 'Book club')));
    verify(() => local.saveGroup(const Group(id: 5, name: 'Book club'))).called(1);
  });

  test('createGroup propagates a failure without touching local storage', () async {
    const failure = NetworkFailure();
    when(() => remote.createGroup(any())).thenAnswer((_) async => const Left(failure));

    final result = await repository.createGroup(name: 'Book club');

    expect(result, const Left(failure));
    verifyNever(() => local.saveGroup(any()));
  });

  test('updateGroup maps the response to an entity and saves it locally', () async {
    when(() => remote.updateGroup(any()))
        .thenAnswer((_) async => const Right(GroupResponse(id: 1, name: 'The Family')));

    final result = await repository.updateGroup(id: 1, name: 'The Family');

    expect(result, const Right(Group(id: 1, name: 'The Family')));
    verify(() => local.saveGroup(const Group(id: 1, name: 'The Family'))).called(1);
  });

  test('watchGroups delegates straight to the local data source', () {
    when(() => local.watchGroups(search: 'fam', limit: 20)).thenAnswer(
      (_) => Stream.value(const [Group(id: 1, name: 'Family')]),
    );

    final stream = repository.watchGroups(search: 'fam', limit: 20);

    expect(stream, emits(const [Group(id: 1, name: 'Family')]));
  });

  test('countGroups delegates straight to the local data source', () async {
    when(() => local.countGroups(search: null)).thenAnswer((_) async => 7);

    final count = await repository.countGroups();

    expect(count, 7);
  });
}

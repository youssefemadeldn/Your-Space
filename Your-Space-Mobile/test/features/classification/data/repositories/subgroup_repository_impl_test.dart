import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/features/classification/data/datasources/base_subgroup_data_source.dart';
import 'package:your_space_mobile/features/classification/data/datasources/subgroup_local_data_source_impl.dart';
import 'package:your_space_mobile/features/classification/data/models/create_subgroup_request.dart';
import 'package:your_space_mobile/features/classification/data/models/subgroup_response.dart';
import 'package:your_space_mobile/features/classification/data/models/update_subgroup_request.dart';
import 'package:your_space_mobile/features/classification/data/repositories/subgroup_repository_impl.dart';

class MockBaseSubGroupDataSource extends Mock implements BaseSubGroupDataSource {}

class MockSubGroupLocalDataSourceImpl extends Mock implements SubGroupLocalDataSourceImpl {}

void main() {
  late MockBaseSubGroupDataSource remote;
  late MockSubGroupLocalDataSourceImpl local;
  late SubGroupRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const SubGroup(id: 0, groupId: 0, name: ''));
    registerFallbackValue(const CreateSubGroupRequest(name: ''));
    registerFallbackValue(const UpdateSubGroupRequest(name: ''));
  });

  setUp(() {
    remote = MockBaseSubGroupDataSource();
    local = MockSubGroupLocalDataSourceImpl();
    repository = SubGroupRepositoryImpl(remote, local);
    when(() => local.saveSubGroup(any())).thenAnswer((_) async {});
    when(() => local.deleteSubGroupLocal(any())).thenAnswer((_) async {});
  });

  test('getSubGroups maps a paginated response to a PaginatedResult of entities', () async {
    when(() => remote.getSubGroups(groupId: 7, search: any(named: 'search'), pageIndex: 1, pageSize: 20))
        .thenAnswer(
      (_) async => const Right(PaginatedResponse(
        items: [
          SubGroupResponse(id: 1, groupId: 7, name: 'Immediate Family'),
          SubGroupResponse(id: 2, groupId: 7, name: 'University Friends'),
        ],
        pageIndex: 1,
        totalPages: 1,
        totalItems: 2,
      )),
    );

    final result = await repository.getSubGroups(groupId: 7, pageIndex: 1, pageSize: 20);

    expect(result.isRight(), isTrue);
    final page = result.getOrElse(() => throw StateError('expected Right'));
    expect(page.items.map((s) => s.name), ['Immediate Family', 'University Friends']);
    expect(page.totalItems, 2);
  });

  test('getSubGroups propagates a failure unchanged', () async {
    const failure = NetworkFailure();
    when(() => remote.getSubGroups(groupId: 7, search: any(named: 'search'), pageIndex: 1, pageSize: 20))
        .thenAnswer((_) async => const Left(failure));

    final result = await repository.getSubGroups(groupId: 7, pageIndex: 1, pageSize: 20);

    expect(result, const Left(failure));
  });

  test('watchSubGroups delegates straight to the local data source', () {
    when(() => local.watchSubGroups(groupId: 7, search: 'im', limit: 20)).thenAnswer(
      (_) => Stream.value(const [SubGroup(id: 1, groupId: 7, name: 'Immediate Family')]),
    );

    final stream = repository.watchSubGroups(groupId: 7, search: 'im', limit: 20);

    expect(stream, emits(const [SubGroup(id: 1, groupId: 7, name: 'Immediate Family')]));
  });

  test('countSubGroups delegates straight to the local data source', () async {
    when(() => local.countSubGroups(groupId: 7, search: null)).thenAnswer((_) async => 5);

    final count = await repository.countSubGroups(groupId: 7);

    expect(count, 5);
  });

  test('createSubGroup maps the response to an entity and saves it locally', () async {
    when(() => remote.createSubGroup(7, any()))
        .thenAnswer((_) async => const Right(SubGroupResponse(id: 5, groupId: 7, name: 'Book club')));

    final result = await repository.createSubGroup(groupId: 7, name: 'Book club');

    expect(result, const Right(SubGroup(id: 5, groupId: 7, name: 'Book club')));
    verify(() => local.saveSubGroup(const SubGroup(id: 5, groupId: 7, name: 'Book club'))).called(1);
  });

  test('createSubGroup propagates a failure without touching local storage', () async {
    const failure = NetworkFailure();
    when(() => remote.createSubGroup(7, any())).thenAnswer((_) async => const Left(failure));

    final result = await repository.createSubGroup(groupId: 7, name: 'Book club');

    expect(result, const Left(failure));
    verifyNever(() => local.saveSubGroup(any()));
  });

  test('updateSubGroup maps the response to an entity and saves it locally', () async {
    when(() => remote.updateSubGroup(7, 1, any())).thenAnswer(
      (_) async => const Right(SubGroupResponse(id: 1, groupId: 7, name: 'Immediate Family (Updated)')),
    );

    final result = await repository.updateSubGroup(groupId: 7, id: 1, name: 'Immediate Family (Updated)');

    expect(result, const Right(SubGroup(id: 1, groupId: 7, name: 'Immediate Family (Updated)')));
    verify(() => local.saveSubGroup(const SubGroup(id: 1, groupId: 7, name: 'Immediate Family (Updated)'))).called(1);
  });

  test('deleteSubGroup removes the row locally after a successful remote delete', () async {
    when(() => remote.deleteSubGroup(7, 1)).thenAnswer((_) async => const Right(unit));

    final result = await repository.deleteSubGroup(groupId: 7, id: 1);

    expect(result, const Right(unit));
    verify(() => local.deleteSubGroupLocal(1)).called(1);
  });

  test('deleteSubGroup propagates a failure without touching local storage', () async {
    const failure = NetworkFailure();
    when(() => remote.deleteSubGroup(7, 1)).thenAnswer((_) async => const Left(failure));

    final result = await repository.deleteSubGroup(groupId: 7, id: 1);

    expect(result, const Left(failure));
    verifyNever(() => local.deleteSubGroupLocal(any()));
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/features/classification/data/models/subgroup_changes_response.dart';

void main() {
  test('fromJson parses upserts, tombstoneIds, cursor, and hasMore', () {
    final json = {
      'upserts': [
        {
          'id': 1,
          'groupId': 7,
          'name': 'Close Friends',
          'nameAr': 'أصدقاء مقربون',
          'updatedAt': '2026-09-13T00:00:00.000Z',
          'syncVersion': 42,
        },
      ],
      'tombstoneIds': [5, 9],
      'cursor': 137,
      'hasMore': false,
    };

    final response = SubGroupChangesResponse.fromJson(json);

    expect(response.upserts, hasLength(1));
    expect(response.upserts.single.id, 1);
    expect(response.upserts.single.updatedAt, DateTime.parse('2026-09-13T00:00:00.000Z'));
    expect(response.tombstoneIds, [5, 9]);
    expect(response.cursor, 137);
    expect(response.hasMore, isFalse);
  });

  test('fromJson handles an empty page', () {
    final json = {
      'upserts': <dynamic>[],
      'tombstoneIds': <dynamic>[],
      'cursor': 0,
      'hasMore': false,
    };

    final response = SubGroupChangesResponse.fromJson(json);

    expect(response.upserts, isEmpty);
    expect(response.tombstoneIds, isEmpty);
    expect(response.cursor, 0);
    expect(response.hasMore, isFalse);
  });

  test('an upsert row with no updatedAt parses updatedAt as null', () {
    final json = {
      'upserts': [
        {'id': 1, 'groupId': 7, 'name': 'Close Friends'},
      ],
      'tombstoneIds': <dynamic>[],
      'cursor': 1,
      'hasMore': true,
    };

    final response = SubGroupChangesResponse.fromJson(json);

    expect(response.upserts.single.updatedAt, isNull);
    expect(response.hasMore, isTrue);
  });
}

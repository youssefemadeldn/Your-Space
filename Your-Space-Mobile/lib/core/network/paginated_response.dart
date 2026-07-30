import 'package:your_space_mobile/core/entities/paginated_result.dart';

/// Parses the backend's `PaginatedResultDto<T>` shape — `{ items, pageIndex,
/// pageSize, totalItems, totalPages }` — found inside the `data` field of
/// every list endpoint's `ServiceResult` envelope. Pair with
/// `unwrapServiceResult` the same way any other response model is:
/// ```dart
/// fromJson: (json) => unwrapServiceResult(
///   json,
///   (inner) => PaginatedResponse.fromJson(
///     inner as Map<String, dynamic>,
///     (item) => GroupResponse.fromJson(item as Map<String, dynamic>),
///   ),
/// ),
/// ```
class PaginatedResponse<T> {
  final List<T> items;
  final int pageIndex;
  final int totalPages;
  final int totalItems;

  const PaginatedResponse({
    required this.items,
    required this.pageIndex,
    required this.totalPages,
    required this.totalItems,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? item) itemFromJson,
  ) {
    final items = json['items'] as List<dynamic>? ?? const [];
    return PaginatedResponse(
      items: items.map(itemFromJson).toList(),
      pageIndex: json['pageIndex'] as int,
      totalPages: json['totalPages'] as int,
      totalItems: json['totalItems'] as int,
    );
  }

  /// Maps each response-model item to its entity, producing the
  /// domain-crossing `PaginatedResult<R>`.
  PaginatedResult<R> toResult<R>(R Function(T item) mapItem) => PaginatedResult<R>(
        items: items.map(mapItem).toList(),
        pageIndex: pageIndex,
        totalPages: totalPages,
        totalItems: totalItems,
      );
}

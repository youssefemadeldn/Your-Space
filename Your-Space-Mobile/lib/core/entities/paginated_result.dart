import 'package:equatable/equatable.dart';

/// Domain-level paginated page of entities — crosses into presentation like
/// any entity. The data-layer counterpart is `PaginatedResponse<T>`
/// (`core/network/paginated_response.dart`), which never crosses this
/// boundary itself.
class PaginatedResult<T> extends Equatable {
  final List<T> items;
  final int pageIndex;
  final int totalPages;
  final int totalItems;

  const PaginatedResult({
    required this.items,
    required this.pageIndex,
    required this.totalPages,
    required this.totalItems,
  });

  bool get hasNextPage => pageIndex < totalPages;

  @override
  List<Object?> get props => [items, pageIndex, totalPages, totalItems];
}

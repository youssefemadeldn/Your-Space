import 'package:equatable/equatable.dart';

/// Mirrors `BulkAddGuestsResultDto`.
class BulkAddGuestsResult extends Equatable {
  final int requestedCount;
  final int addedCount;
  final int alreadyPresentCount;

  const BulkAddGuestsResult({
    required this.requestedCount,
    required this.addedCount,
    required this.alreadyPresentCount,
  });

  @override
  List<Object?> get props => [requestedCount, addedCount, alreadyPresentCount];
}

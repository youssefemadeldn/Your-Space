import 'package:your_space_mobile/features/events/domain/entities/bulk_add_guests_result.dart';

class BulkAddGuestsResultResponse {
  final int requestedCount;
  final int addedCount;
  final int alreadyPresentCount;

  const BulkAddGuestsResultResponse({
    required this.requestedCount,
    required this.addedCount,
    required this.alreadyPresentCount,
  });

  factory BulkAddGuestsResultResponse.fromJson(Map<String, dynamic> json) => BulkAddGuestsResultResponse(
        requestedCount: json['requestedCount'] as int,
        addedCount: json['addedCount'] as int,
        alreadyPresentCount: json['alreadyPresentCount'] as int,
      );

  BulkAddGuestsResult toEntity() => BulkAddGuestsResult(
        requestedCount: requestedCount,
        addedCount: addedCount,
        alreadyPresentCount: alreadyPresentCount,
      );
}

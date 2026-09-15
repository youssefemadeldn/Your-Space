/// Parses `PersonImageProfileDto`'s fields (row 9.15/9.16's flat "all mine"
/// endpoint) — deliberately a separate model from `PersonImageResponse`,
/// which carries a presigned `url` instead of `objectKey`. A presigned URL
/// expires within minutes/hours and must never be cached as if stable; this
/// shape exists purely to feed the local bookkeeping cache (what images
/// exist, which is primary), never anything renderable.
class PersonImageProfileResponse {
  final int id;
  final int personId;
  final String objectKey;
  final bool isPrimary;

  const PersonImageProfileResponse({
    required this.id,
    required this.personId,
    required this.objectKey,
    required this.isPrimary,
  });

  factory PersonImageProfileResponse.fromJson(Map<String, dynamic> json) => PersonImageProfileResponse(
        id: json['id'] as int,
        personId: json['personId'] as int,
        objectKey: json['objectKey'] as String,
        isPrimary: json['isPrimary'] as bool,
      );
}

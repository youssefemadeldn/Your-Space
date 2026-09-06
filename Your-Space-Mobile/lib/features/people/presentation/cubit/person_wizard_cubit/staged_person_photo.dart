import 'dart:io';

/// A photo tile in the wizard's Step 1 grid — either a freshly-picked local
/// file (not yet uploaded) or a pre-existing server photo (Edit mode, shown
/// as a network tile). Nothing uploads/deletes until the final submit — see
/// `PersonWizardCubit`'s locked staged-photo model.
class StagedPersonPhoto {
  final String localId;
  final File? localFile;
  final int? existingImageId;
  final String? existingUrl;
  final bool isPrimary;

  const StagedPersonPhoto({
    required this.localId,
    this.localFile,
    this.existingImageId,
    this.existingUrl,
    required this.isPrimary,
  });

  bool get isExisting => existingImageId != null;

  StagedPersonPhoto copyWith({bool? isPrimary}) => StagedPersonPhoto(
        localId: localId,
        localFile: localFile,
        existingImageId: existingImageId,
        existingUrl: existingUrl,
        isPrimary: isPrimary ?? this.isPrimary,
      );
}

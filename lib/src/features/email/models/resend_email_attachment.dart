/// Email attachment (max 40mb per email)
class ResendEmailAttachment {
  /// Content of an attached file.
  final StringBuffer buffer;

  /// Name of attached file.
  final String fileName;

  /// Path where the attachment file is hosted.
  final String path;

  /// Content type for the attachment, if not set will be derived from the filename property.
  final String contentType;

  /// Constructor of ResendEmailAttachment
  const ResendEmailAttachment(
      {required this.buffer,
      required this.fileName,
      required this.path,
      required this.contentType});
}

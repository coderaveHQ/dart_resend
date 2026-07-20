import 'package:dart_resend/dart_resend.dart';

/// Creates a contact segment.
Future<ResendResponse<ResendId>> createSegment(Resend resend) {
  return resend.segments.create(CreateSegmentRequest(name: 'Customers'));
}

/// Lists contact segments.
Future<ResendResponse<ResendPage<Segment>>> listSegments(Resend resend) {
  return resend.segments.list(pagination: PaginationOptions(limit: 25));
}

/// Retrieves a contact segment.
Future<ResendResponse<Segment>> retrieveSegment(
  Resend resend,
  String segmentId,
) {
  return resend.segments.retrieve(segmentId);
}

/// Lists the contacts in a segment.
Future<ResendResponse<ResendPage<Contact>>> listSegmentContacts(
  Resend resend,
  String segmentId,
) {
  return resend.segments.listContacts(
    segmentId,
    pagination: PaginationOptions(limit: 100),
  );
}

/// Deletes a contact segment.
Future<ResendResponse<ResendDeletion>> deleteSegment(
  Resend resend,
  String segmentId,
) {
  return resend.segments.delete(segmentId);
}

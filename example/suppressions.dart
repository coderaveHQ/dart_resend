import 'package:dart_resend/dart_resend.dart';

/// Adds one address to the suppression list.
///
/// The Resend Suppressions API is currently a gated private beta.
Future<ResendResponse<ResendId>> addSuppression(Resend resend) {
  return resend.suppressions.add('blocked@example.com');
}

/// Adds up to 100 addresses to the suppression list.
Future<ResendResponse<ResendCollection<ResendId>>> addSuppressions(
  Resend resend,
) {
  return resend.suppressions.addBatch(<String>[
    'blocked@example.com',
    'complaint@example.com',
  ]);
}

/// Retrieves a suppression by ID or email address.
Future<ResendResponse<Suppression>> retrieveSuppression(
  Resend resend,
  String idOrEmail,
) {
  return resend.suppressions.retrieve(idOrEmail);
}

/// Lists suppressions and optionally filters by their origin.
Future<ResendResponse<ResendPage<Suppression>>> listSuppressions(
  Resend resend,
) {
  return resend.suppressions.list(
    origin: SuppressionOrigin.bounce,
    pagination: PaginationOptions(limit: 25),
  );
}

/// Removes one suppression by ID or email address.
Future<ResendResponse<ResendDeletion>> removeSuppression(
  Resend resend,
  String idOrEmail,
) {
  return resend.suppressions.remove(idOrEmail);
}

/// Removes suppressions selected by email address.
Future<ResendResponse<ResendCollection<ResendDeletion>>>
removeSuppressionsByEmail(Resend resend) {
  return resend.suppressions.removeBatch(
    RemoveSuppressionsRequest.byEmails(<String>[
      'blocked@example.com',
      'complaint@example.com',
    ]),
  );
}

/// Removes suppressions selected by suppression ID.
Future<ResendResponse<ResendCollection<ResendDeletion>>> removeSuppressionsById(
  Resend resend,
  List<String> suppressionIds,
) {
  return resend.suppressions.removeBatch(
    RemoveSuppressionsRequest.byIds(suppressionIds),
  );
}
